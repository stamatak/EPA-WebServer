require 'raxml_alignmentfile_parser'
require 'raxml_treefile_parser'
require 'raxml_partitionfile_parser'
require 'raxml_queryfile_parser'

#### The main RAxML Objekt that contains the main Job submission informations and validates the input files and parameters

class Raxml < ActiveRecord::Base

  ### Standard validator functions
  validates_presence_of :alifile, :treefile
  validates_presence_of :queryfile, :parfile, :if => :mga_selected?
  validates_format_of :email, :with => /\A([^@\s])+@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i , :on => :save, :message => "Invalid address", :allow_blank => true
  validates_numericality_of :b_random_seed,  :only_integer => true, :greater_than => 0,  :message => "Input must be an integer and greater than 0 and less than 101"
  validates_numericality_of :b_runs, :only_integer => true, :greater_than => 0, :less_than => 101, :message => "Input must be an integer and greater than 0 and less than 101"
  
  validates_presence_of :parfile, :if => :par_selected?
  validates_presence_of :queryfile, :if => :queryfile_selected?

  ## checks if the Partition file option has been checked 
  def par_selected?
    if self.query.eql?("PAR")
      return true
    else
      return false
    end
  end

  ## checks if the "Upload ualigned query reads" otption has been checked 
  def queryfile_selected?
    if self.use_queryfile.eql?("T")
      return true
    else
      return false
    end
  end

  ## checks if we have a multi gene submission
  def mga_selected?
    if self.mga.eql?("T")
      return true
    else
      return false
    end
  end

  ## custom validator function that checks the file formats of the uploaded Alignemntfile , Treefile, Partitionfile and the Sequencefile with the unaligned reads.
  def validate
    jobdir = "#{RAILS_ROOT}/public/jobs/#{self.jobid}/"
    if (!(self.alifile.eql?("")) && !(self.treefile.eql?(""))) &&  (!(self.alifile.nil?) && !(self.treefile.nil?))
      a = RaxmlAlignmentfileParser.new(self.alifile, self.substmodel, self.parfile)
      errors.add(:alifile, a.error) if !(a.valid_format)
      if a.valid_format
        alifile_path =  jobdir+"alignment_file"
        saveOnDisk(a.data,alifile_path)
        self.alifile = alifile_path
      end
      
      t = RaxmlTreefileParser.new(self.treefile)
      errors.add(:treefile, t.error) if !(t.valid_format)
      if t.valid_format
          treefile_path =  jobdir+"tree_file"
          saveOnDisk(t.data,treefile_path)
          self.treefile = treefile_path
      end

      if ((self.query.eql?("PAR") && !(self.parfile.eql?("") )) || self.mga.eql?("T")) && ((self.query.nil? && !(self.parfile.nil?)) || self.mga.eql?("T")) 
        p = RaxmlPartitionfileParser.new(self.parfile,a.ali_length)
        errors.add(:parfile, p.error) if !(p.valid_format)
        if p.valid_format
          parfile_path =  jobdir+"partition_file"
          saveOnDisk(p.data,parfile_path)
          self.parfile = parfile_path
        end
      end
      if ((self.use_queryfile.eql?("T") && !(self.queryfile.eql?(""))) || self.mga.eql?("T")) && ((self.use_queryfile.nil? && !(self.queryfile.nil?)) || self.mga.eql?("T"))
        q = RaxmlQueryfileParser.new(self.queryfile)
        errors.add(:queryfile, q.error) if !(q.valid_format) 
        if q.valid_format
          queryfile_path =  jobdir+"queryfile"
          saveOnDisk(q.data,queryfile_path)
          self.queryfile = queryfile_path
        end
      end
    end
  end

  ## Saves the Input files on the job directory on disk 
  def saveOnDisk(data,path)
    if  data.instance_of?(Array)
        File.open(path,'wb'){|f| f.write(data.join)}
    elsif data.instance_of?(String)
      File.open(path,'wb'){|f| f.write(data)}
    else
      raise "Error: Unknown Datatype"
    end
  end

  ## collects the options for "raxml_and_send_email.rb" including the options for all following processing steps (RAxML, Uclust,Hmmer) and builds a shell file that is submited in the Batch system. 
  def execude(link,id)
        
    opts = {"-s" => self.alifile, "-n" => self.outfile, "-m" => self.substmodel,  "-f" => self.speed  , "-link" => link, "-id" => id}  # id contains the job id 
    if emailValid?
      opts["-email"] = self.email
    end
    if !(self.treefile.nil?)
      opts["-t"] = self.treefile
    end
    if self.query.eql?("PAR") || self.mga.eql?("T")
      opts["-q"] = self.parfile
    end
    if self.use_heuristic.eql?("T")
     # if self.heuristic.eql?("MP")
     #   if self.h_value =~ /(1)\/(\d+)/
     #     opts["-H"] = (($1.to_f)/($2.to_f)).to_s
     #   end
    #  elsif self.heuristic.eql?("ML")
        if self.h_value =~ /(1)\/(\d+)/
          opts["-G"] = (($1.to_f)/($2.to_f)).to_s
        end
      end
 #   elsif self.use_bootstrap.eql?("T")
 #     opts["-x"] = self.b_random_seed
 #     opts["-N"] = self.b_runs
 #   end
    if self.use_queryfile.eql?("T")
      opts["-useQ"] = self.queryfile
      if self.use_clustering.eql?("T")
        opts["-useCl"] = ""
      end
      if self.use_papara.eql?("T")
        opts["-papara"] = ""
      end
    end
  #  if self.use_clustering.eql?("T")
  #    opts["-useCl"] = ""
  #  end
    if self.mga.eql?("T")
      opts["-mga"] = ""
    end
 #   if self.use_papara.eql?("T")
 #     opts["-papara"] = ""
 #   end
    cores = parseDescription(self.job_description)
    if cores > 1
      opts["-T"] = cores
    end
    
    # Build shell file  
    path = "#{RAILS_ROOT}/public/jobs/#{id}"
    shell_file = "#{RAILS_ROOT}/public/jobs/#{id}/submit.sh"
    command = "#{RAILS_ROOT}/bioprogs/ruby/raxml_and_send_email.rb"
    opts.each_key {|k| command  = command+" "+k+" #{opts[k]} "}
    puts command
    File.open(shell_file,'wb'){|file| file.write(command+";echo done!")}

    # submit shellfile into batch system 
    system "qsub -o #{path} -j y #{shell_file} "
  end

  ## checks email format
  def emailValid?
    if self.email =~ /\A([^@\s])+@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      return true
    else
      return false
    end      
  end

  ## Sends the message entered via the contact formular on the webpage to the administrators (Alexi,Simon,Denis)
  def Raxml.sendMessage(name,email,subject,message)  
    command = "#{RAILS_ROOT}/bioprogs/ruby/send_message.rb "
    if !(name.nil? || name.eql?(""))
      command = command+" -n #{name} "
    end
    if email=~/^\S+@\S+/
      command = command+" -e #{email} "
    end
    if !(subject.nil? || subject.eql?(""))
      command = command+" -s #{subject} "
    end
    command = command+" -m #{message} "
    puts command
    system command # if more traffic on the server is occuring (at this moment, the server can handle three parallel requests)  this should be submitted to the batch system
    return true
  end

  # check description for parallel instructions 
  def parseDescription(desc)
    if desc =~ /<\?(\d+)\?>/
      puts "####"+$1
      return $1.to_i
    else
      return 1
    end
  end

  # find_first
  def self.findWithException(*args)
    options = args.extract_options!
    rax = nil
 
   
    case args.first
    when :first then rax = find(:first,options)
    when :last  then rax = find(:last, options)
    when :all   then rax = find(:all, options)
    else             rax = find(args, options)
    end
    if rax.nil?
      raise ActiveRecord::RecordNotFound
    else
      return rax
    end
  end

end
