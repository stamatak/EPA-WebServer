require 'rubygems'
require 'popen4'
require "#{RAILS_ROOT}/app/models/fasta_to_phylip.rb"

class RaxmlAlignmentfileParser
  
attr_reader :format, :valid_format, :error ,:data , :ali_length, :log, :het_model, :partition_file
  def initialize(stream, het_model, partition_file)
    @het_model = het_model
    @partition_file = partition_file
    @log = []
    @filename = ""
    @data = []
    if stream.instance_of?(String) #because of testing
      if stream =~ /\S+\/(\w+\.phylip)$/
        @filename = $1
      end
      f = File.open(stream,'r')
      @data = f.readlines
      f.close
    else
      @filename = stream.original_filename
      @data = stream.readlines 
    end
    @format = "unk"
    @valid_format = false
    @error = ""
    @message = "Invalid alignmentfile format!(Only Fasta and Phylip alignment formats are allowed)  ParserError :: #{@filename}<br></br>"
    check_format
    @ali_length = 0
    if @valid_format
      @data.each do |line|
        if line=~ /\d+\s+(\d+)/
          @ali_length = $1.to_i
        end
      end
    end
  end

  private
  def check_format
    i = 0
    while i < @data.size
      
      if @data[i] =~ /^>/ && @data[i+1]=~ /^([A-Z\-]+)\s*$/ #fasta format?
        @format = "fas"
        @data[i+1].gsub!(/\./,"-")
        @valid_format = true
        j = i+2
        while j < @data.size
          if !(@data[j] =~ /^[A-Z\-]+\s*$/ || (@data[j] =~  /^>/ && @data[j+1]=~ /^[A-Z\-]+\s*$/))
            @format = "unk"
            @valid_format = false
            @error = "#{@message} line #{j}: *#{@data[j]}*"
            return
          elsif @data[j] =~ /^[A-Z\-]+\s*$/
            @data[j].gsub!(/\./,"-")
          end
            
        j = j+1
        end
        @data = FastaToPhylip.new(@data).phylip.join("\n")
        checkPhylipFormatWithRaxml
        break

      elsif @data[i] =~ /\s*\d+\s+\d+/  #phylip format?
        @format = "phl"
        @valid_format = true
        checkUniquenessOfNames
        checkPhylipFormatWithRaxml
        break

      elsif @data[i] =~ /^\s+$/ # blank lines are ignored
        #do nothing

      else
        @error = @message
        break
      end
      i = i+1
    end
  end

  private
  def checkUniquenessOfNames
    names = {}
    first_name = ""
    seqs = 0;
    seq_len = 0;
    read_names = false
    data_copy = Array.new(@data)
    @data.each do |line|
      if line =~ /\s*(\d+)\s+(\d+)/
        seqs = $1.to_i
        seq_len = $2.to_i
      elsif line =~  /^\s+$/
        #all names have been read, quit procedure
        #clear the names hash 
        #rename again
        if read_names
          read_names = false
          if names.size > seqs
            @data = data_copy
            @log << "RAxML_Alignmentfile_parser couldn't read format! Reseted alignmentfile!"
            return
          end
          names = {}
        end
      elsif line =~ /\s*\S+\s*/ #A sequence line is read
        if names.size > seqs
          @data = data_copy
          @log << "RAxML_Alignmentfile_parser couldn't read format! Reseted alignmentfile! "
          return
        end
        s = line.gsub(/\s/, "")
        # check if line length without whitespaces matches the sequence length given 
        if s.length > seq_len  # Taxon and sequence in the line
          if line =~ /^\s*(\S+)\s+/
            name = $1
            if !read_names 
              if !first_name.eql?(name) && first_name != ""  # interleaved format without reoccurring taxon names
                return
              end
              first_name = name
              read_names = true  
            end
            if names[name].nil?
              names[name] = 1
            else
              names[name] += 1
              line.sub!(/^\s*(\S+)/,name+"_"+names[name].to_s)
              @log << "renamed #{name} to #{name+"_"+names[name].to_s}"
            end
          else
             @error = "ERROR: couldn't parse #{line}"
             @valid_format = false
          end
        elsif s.length < seq_len # Only Taxon in the line or interleaved format
          if line =~ /^\s*(\S+)\s*/
            name = $1
            if !read_names 
              if !first_name.eql?(name) && first_name != "" # interleaved format without reoccurring taxon names
                return
              end
              first_name = name
              read_names = true  
            end
            if names[name].nil?
              names[name] = 1
            else
              names[name] += 1
              line.sub!(/^\s*(\S+)/,name+"_"+names[name].to_s)
              @log << "renamed #{name} to #{name+"_"+names[name].to_s}"
            end
          else
            @error =  "ERROR: couldn't parse #{line}"
            @valid_format = false
          end
        else # Only Sequence in the line
          #do nothing
        end
        
      end
    end #end each
  end


  private
  def checkPhylipFormatWithRaxml
    
    random_number = (1+rand(10000))* (1+(10000%(1+rand(10000))))*(1+rand(10000)) #build random number for @filename to avoid collision
    file = "#{RAILS_ROOT}/tmp/files/#{random_number}_#{@filename}" 
    f = File.open(file,'wb')
    @data.each {|d| f.write(d)}
    f.close
    
    puts "#############"
    puts @het_model
    puts @partition_file
    puts "#############"

    cmd = "#{RAILS_ROOT}/bioprogs/raxml/raxmlHPC-SSE3  -s #{file} -fc -m  #{@het_model} -n checkFormat"
    if !(@partition_file.nil? || @partition_file.eql?(""))
      cmd = cmd + "-q #{@partition_file}"
    end

    #let RAxML check if phylip format is correct
    POpen4::popen4( cmd ) do |stdout, stderr, stdin|
      stdout.each do |line|
        if !(line =~ /^Alignment\sformat\scan\sbe\sread\sby\sRAxML/) && !(line=~ /IMPORTANT\s+WARNING/)
          @error = @error+line
          @format = "unk"
          @valid_format = false
        end
      end
    end 
    if !@error.eql?("")
      @error = "#{@message}\n#{@error}"
    end
     system "rm #{file}"
  end
end

