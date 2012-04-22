class RaxmlController < ApplicationController
  def submit
    @root  = "#{ENV['SERVER_ADDR']}"
    @dna_model_options = ""
    @aa_model_options = ""
    @aa_matrices = ""
    @par_model_options  =""
    @model_options = ""
    @heuristics =""
    @heuristics_values =""
    @ip_counter = 0;
    @submission_counter = 0;
    initialize_options
    @raxml = Raxml.new
  end

  def updateServerStatus
     system "qstat -f > #{RAILS_ROOT}/tmp/files/qstat.log" #update the server capacity utilisation
  end

  def submit_single_gene
    updateServerStatus
    @root  = "#{ENV['SERVER_ADDR']}"
    @dna_model_options = ""
    @aa_model_options = ""
    @aa_matrices = ""
    @par_model_options  =""
    @heuristics =""
    @heuristics_values =""
    @ip_counter = 0;
    @submission_counter = 0;
    initialize_options
    @raxml = Raxml.new
  end

  def submit_multi_gene
    updateServerStatus
    @root  = "#{ENV['SERVER_ADDR']}"
    @model_options = ""
    @matrices = ""
    @heuristics =""
    @heuristics_values =""
    @ip_counter = 0;
    @submission_counter = 0;
    initialize_options_mga
    @raxml = Raxml.new
  end

  def initialize_options_mga
    models = ["GAMMA","CAT", "CATI","GAMMAI"]
    models.each {|m| @model_options= @model_options+"<option>#{m}</option>"}
    matrices = ["DAYHOFF", "DCMUT", "JTT", "MTREV", "WAG", "RTREV", "CPREV", "VT", "BLOSUM62", "MTMAM", "LG"]
    matrices.each {|m| @matrices= @matrices+"<option>#{m}</option>"}
    heuristics = ["ML"]
    heuristics.each {|h| @heuristics = @heuristics+"<option>#{h}</option>"}
    heuristics_values = ["1/2","1/4","1/8","1/16","1/32","1/64"]
    heuristics_values.each do |h| 
      if h.eql?("1/16")
         @heuristics_values = @heuristics_values+"<option selected=\"selected\">#{h}</option>"
      else
        @heuristics_values = @heuristics_values+"<option>#{h}</option>"
      end
    end
    
    getInfo
    
  end
  


  def initialize_options
    models = ["GTRGAMMA","GTRCAT", "GTRCATI","GTRGAMMAI"]
    models.each {|m| @dna_model_options= @dna_model_options+"<option>#{m}</option>"}
    models = ["PROTGAMMA","PROTGAMMAI","PROTCAT","PROTCATI"]
    models.each {|m| @aa_model_options= @aa_model_options+"<option>#{m}</option>"}
    matrices = ["DAYHOFF", "DCMUT", "JTT", "MTREV", "WAG", "RTREV", "CPREV", "VT", "BLOSUM62", "MTMAM", "LG"]
    matrices.each {|m| @aa_matrices= @aa_matrices+"<option>#{m}</option>"}
    models = ["GAMMA", "GAMMAI", "CAT", "CATI"]
    models.each {|m| @par_model_options= @par_model_options+"<option>#{m}</option>"}
    heuristics = ["ML"]
    heuristics.each {|h| @heuristics = @heuristics+"<option>#{h}</option>"}
    heuristics_values = ["1/2","1/4","1/8","1/16","1/32","1/64"]
    heuristics_values.each do |h| 
      if h.eql?("1/16")
        @heuristics_values = @heuristics_values+"<option selected=\"selected\">#{h}</option>"
      else
        @heuristics_values = @heuristics_values+"<option>#{h}</option>"
      end
    end
    getInfo
    
  end

  def getInfo

    # Visitors, job Submission infos
    ips = Userinfo.find(:all)
    if ips.size == 0
      @ip_counter=0;
       @submission_counter = 0;
    else
      @ip_counter = (ips.size) - 1   # - c.c.c.c
      userinfo  = Userinfo.find(:first, :conditions => {:ip => "c.c.c.c"})
      @submission_counter = userinfo.overall_submissions
    end

    # Server capacity utilisation infos
    @slots = 0
    @used_slots = 0
    q = QstatFileParser.new(RAILS_ROOT+"/tmp/files/qstat.log")
    @slots = q.slots
    @used_slots = q.used_slots
    # submitJob and results should always update the status file. 
  end

  def submitJob
    @jobid = generateJobID
    if !(params[:jobid].nil?)  ## quick hack such that the testing only generates Jobs with the ID 110.
      @jobid  = "110"          #
    end                        #
    @dna_model_options  = ""
    @aa_model_options   = ""
    @aa_matrices        = ""
    @par_model_options  = ""
    @model_options      = ""
    @matrices           = ""
    @heuristics         = ""
    @heuristics_values  = ""
    @ip_counter         = 0;
    @submission_counter = 0;
    initialize_options
    
    @direcrory       = nil
    @ip              = request.remote_ip
    @alifile         = params[:alifile]
    @treefile        = params[:treefile]
    @queryfile       = params[:queryfile]
    @parfile         = params[:parfile]
    @outfile         = ""
    @query           = ""
   # @speed          = params[:chSpeed]
    @speed           = "F" # no fast insertion option anymore
    @substmodel      = ""
    @matrix          = nil
    @sm_float        = nil
    @use_queryfile   = params[:qfile]
    @use_clustering  = params[:cluster]
    @use_bootstrap   = params[:chBoot]
    @use_papara      = params[:papara]
    @b_random_seed   = 1234
    @b_runs          = 100
    @use_heuristic   = params[:chHeu]
    @heuristic       = ""
    @h_value         = ""
    @email           = params[:rax_email]
    @job_description = params[:job_desc].gsub(/\s/,"__"); ### save that nobody enters sql syntax
    @mga             = "F"

    # Multi gene mode?
    if params[:modus].eql?("mga")
      @mga = "T"
      initialize_options_mga
    end

    # if multi gene mode
    if @mga.eql?("T")
      # Check Query Type (DNA|AA)
      @query = "MGA"
      @substmodel = "#{params[:substmodel]}"
      if !(@use_clustering.eql?("T"))
        @use_clustering ="F"
      end
      @use_queryfile ="T"
 #     @queryfile = params[:raxml][:queryfile]
 #     @parfile = params[:raxml][:parfile]
    # else single gene mode
    else
      # Check Query Type (DNA|AA|PAR)
       @query = params[:query]
      if @query.eql?("DNA")
        @substmodel = "#{params[:dna_substmodel]}"
      elsif @query.eql?("AA")
        @substmodel = params[:aa_substmodel]
        @matrix = params[:matrix]
        @sm_float = params[:sm_float]
        @substmodel = "#{@substmodel}#{@matrix}#{@sm_float}"
      elsif @query.eql?("PAR")
        @substmodel = "GTR#{params[:par_substmodel]}"
#        @parfile = params[:raxml][:parfile]      
      end

      # Upload a query read file?
      if !(@use_queryfile.eql?("T"))
     #   @queryfile = params[:raxml][:queryfile]
     # else
        @use_queryfile = "F"
      end

      #check if papara is selected and the input is DNA, upload query reads has to be checked
      if !@use_papara.eql?("T") || !@query.eql?("DNA") || @use_queryfile.eql?("F")
        @use_papara = "F"
      end

      # Cluster uploded reads? Upload query reads has to be checked
      if !(@use_clustering.eql?("T")) || @use_queryfile.eql?("F")
        @use_clustering ="F"
      end
    end

    if @speed.eql?("T")
      @speed = "y"
    else
      @speed = "v"
    end

    # Use heuristics?
    if  @use_heuristic.eql?("T")
      @heuristic = params[:heuristic]
      @h_value = params[:heu_float]
    else
      @use_heuristic = "F"
    end
    
    # Use bootstrapping?
    if @use_bootstrap.eql?("T")
      @b_random_seed = params[:random_seed]
      @b_runs = params[:runs]
    else
      @use_bootstrap = "F"
    end
   
     buildJobDir
    @raxml = Raxml.new({ :alifile         => @alifile ,
                         :query           => @query, 
                         :outfile         => @outfile, 
                         :speed           => @speed, 
                         :substmodel      => @substmodel, 
                         :heuristic       => @heuristic, 
                         :treefile        => @treefile, 
                         :email           => @email, 
                         :h_value         => @h_value, 
                         :errorfile       => "", 
                         :use_heuristic   => @use_heuristic, 
                         :use_bootstrap   => @use_bootstrap, 
                         :b_random_seed   => @b_random_seed, 
                         :b_runs          => @b_runs , 
                         :parfile         => @parfile, 
                         :use_queryfile   => @use_queryfile, 
                         :queryfile       => @queryfile, 
                         :use_clustering  => @use_clustering, 
                         :jobid           => @jobid, 
                         :user_ip         => @ip, 
                         :job_description => @job_description, 
                         :status          => "running" , 
                         :mga             => @mga, 
                         :use_papara      => @use_papara})
    
    if @raxml.save
      @raxml.update_attribute(:outfile,"#{@raxml.jobid}")
      link = url_for :controller => 'raxml', :action => 'results', :id => @raxml.jobid 
      @raxml.execude(link,@raxml.jobid.to_s)

      ## save userinfos
      ip = @ip
      if ip.eql?("") || ip.nil?
        ip = "xxx.xxx.xxx.xxx"
      end
      if Userinfo.exists?(:ip => ip)
        userinfo = Userinfo.find(:first, :conditions => {:ip => ip})
        userinfo.update_attribute(:saved_submissions, userinfo.saved_submissions+1)
        userinfo.update_attribute(:overall_submissions, userinfo.overall_submissions+1)
      else
        userinfo = Userinfo.new({:ip => ip, :saved_submissions => 1, :overall_submissions => 1})
        userinfo.save
      end
      #### main counter c.c.c.c   ## faster but accurate?
      counter_ip = "c.c.c.c"
      if Userinfo.exists?(:ip => counter_ip)
        userinfo = Userinfo.find(:first, :conditions => {:ip => counter_ip })
        userinfo.update_attribute(:saved_submissions, userinfo.saved_submissions+1)
        userinfo.update_attribute(:overall_submissions, userinfo.overall_submissions+1)
      else
        userinfo = Userinfo.new({:ip => counter_ip, :saved_submissions => 1, :overall_submissions => 1})
        userinfo.save
      end

      sleep 2 #Without this, an error occurs. Somehow the writing in the database is not fast enough
      redirect_to :action => 'wait', :id => @raxml.jobid 
    else
      @raxml.errors.each do |field, error|
        puts field
        puts error
      end
      if @mga.eql?("T")
        render :action => 'submit_multi_gene'
      else
        render :action => 'submit_single_gene'
      end
    end
  end

  def buildJobDir
    @directory = "#{RAILS_ROOT}/public/jobs/#{@jobid}/"
    Dir.mkdir(@directory) rescue system("rm -r #{@directory}; mkdir #{@directory}")
  end

  def generateJobID
    id = "#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"	
    searching_for_valid_id = true
    while searching_for_valid_id
      r = Raxml.find(:first, :conditions => ["jobid = #{id}"])
      if r.nil?
        return id
      end
      id  = "#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
    end 
    return id
  end
   
  def wait
    @ip_counter = 0;
    @submission_counter = 0;
    getInfo
    @raxml = Raxml.findWithException(:first, :conditions => ["jobid = #{params[:id]}"])
    @ip = @raxml.user_ip
    @id = params[:id]
    if !(jobIsFinished?(@raxml.jobid))
      render :action => "wait"
    else
      redirect_to :action => "results" , :id => @raxml.jobid
    end
  end

  def jobIsFinished?(id)
    @raxml = Raxml.find(:first, :conditions => ["jobid = #{id}"]) 
    path = "#{RAILS_ROOT}/public/jobs/#{id}/"
    finished = false
    Dir.glob(path+"submit.sh.*"){|file|
      f = File.open(file,'r')
      fi = f.readlines
      if fi.size > 0
       # if file =~ /submit\.sh\.e/
          
     #     @raxml.update_attribute(:errorfile,file)
     #     f.close
     #     return true
     #   else
        fi.each do |line|
        #  if line =~ /\s+ERROR[\s:]\s*/i
        #    @raxml.update_attribute(:errorfile,file)
        #    return true
          if line =~ /^done!\s*$/
            @raxml.update_attribute(:status,"done") 
            return true
          end
        end
     #   end
      end
      f.close
    }
    return finished       
  end

  def results
    updateServerStatus
    @cites = []
    jobid = params[:id]
    collectCites(jobid)
    @ip_counter = 0;
    @submission_counter = 0;
    @phyloxml_file ="treefile.phyloxml"
    if File.size(RAILS_ROOT+"/public/jobs/"+jobid+"/"+@phyloxml_file) > 5000000
      @phyloxml_file = "treefile_no_placements.phyloxml"
    end
    getInfo
    rax =  Raxml.findWithException(:first, :conditions => ["jobid = #{jobid}"])
    res  =  RaxmlResultsParser.new(rax.outfile)
    @files = res.files
    @names = res.names
    @root  = "#{ENV['SERVER_ADDR']}"
    @path = "/jobs/#{rax.jobid}/"
    if !(rax.errorfile.eql?(""))
      @files << rax.errorfile
      @names << "logfile"
    end

  end
  def collectCites(jobid)
    @cites << "<b>EPA:</b> <li> S.A. Berger, A. Stamatakis, Evolutionary Placement of Short Sequence Reads. <a href=\"http://arxiv.org/abs/0911.2852v1\" target=\"_blank\">arXiv:0911.2852v1</a> [q-bio.GN](2009)</li>"
    @cites << "<b>Archaeopteryx Treeviewer:</b> <li>Han, Mira V.; Zmasek, Christian M. (2009). phyloXML: XML for evolutionary biology and comparative genomics. BMC Bioinformatics (United Kingdom: BioMed Central) 10: 356. doi:10.1186/1471-2105-10-356. <a href=\"http://www.biomedcentral.com/1471-2105/10/356\" target=\"_blank\">http://www.biomedcentral.com/1471-2105/10/356</a></li>"
    @cites << "<li>Zmasek, Christian M.; Eddy, Sean R. (2001). ATV: display and manipulation of annotated phylogenetic trees. Bioinformatics (United Kingdom: Oxford Journals) 17 (4): 383–384. <a href=\"http://bioinformatics.oxfordjournals.org/cgi/reprint/17/4/383\" target=\"_blank\">http://bioinformatics.oxfordjournals.org/cgi/reprint/17/4/383</a></li>"
    @cites << "<b>EDPL:</b><li>Frederick A Matsen, Robin B Kodner and E Virginia Armbrust, pplacer: linear time maximum-likelihood and Bayesian phylogenetic placement of sequences onto a fixed reference tree. <a href=\"http://arxiv.org/abs/1003.5943v1\" target=\"_blank\">arXiv:1003.5943v1</a>  [q-bio.PE]</li>"
    rax =  Raxml.findWithException(:first, :conditions => ["jobid = #{jobid}"])
    if rax.use_clustering.eql?("T") 
      @cites << "<b>Hmmer:</b> <li>S. R. Eddy., A New Generation of Homology Search Tools Based on Probabilistic Inference. Genome Inform., 23:205-211, 2009.</li>"
      @cites << "<b>uclust:</b> <li><a href=\"http://www.drive5.com/uclust\" target=\"_blank\">http://www.drive5.com/uclust</a></li>"
    end

  end
    
  def download 
    file = params[:file]
    send_file file
  end

  def treehelp
    render :layout => false
  end

  def index
    getInfo
  end
  
  def look
    getInfo
    @error_id = ""
    @error_email = ""
    if !(params[:id].nil?)
      @error_id = "The job  with the id \'#{params[:id]}\' does not exists or is not finished yet"
    elsif !(params[:email].nil?) && !(params[:email].eql?("\'\'"))
      @error_email = "No jobs for \'#{params[:email]}\' available!"
    end
  end

  def findJob
    jobid = params[:rax_job]
    if Raxml.exists?(:jobid => jobid)
      if jobIsFinished?(jobid)
        redirect_to :action => "results" , :id => jobid
      else
        redirect_to :action => "look" ,:id => jobid
      end
    else
      redirect_to :action => "look" ,:id => jobid
    end
  end

  def listOldJobs
    jobs_email = params[:rax_email]
    if Raxml.exists?(:email => jobs_email) && (!jobs_email.eql?(""))
     
      redirect_to :action => "allJobs" , :email =>  "\'#{jobs_email}\'"
    else
      redirect_to :action => "look" ,:email => "\'#{jobs_email}\'"
    end
  end

  def allJobs
    getInfo
    @jobs_email = params[:email]
    
    rax =  Raxml.find(:all, :conditions => ["email = #{@jobs_email}"])
    @jobids=[]
    @jobdescs=[]
    @time_left = []
    time_now = Time.new
    time = 60*60*24*7*2 #2 weeks
    rax.each do |r| 
      if jobIsFinished?(r.jobid)
        if r.job_description.eql?("") 
          @jobids << r.jobid
          @jobdescs << "";
        else
          @jobids << r.jobid
          @jobdescs << r.job_description.gsub(/__/," ")
        end
        e = r.created_at.to_s                                                                                                                              
        if  e =~ /(\d+)-(\d+)-(\d+)\s*(\d+):(\d+):(\d+)/                 
          year = $1.to_i
          month = $2.to_i
          day = $3.to_i
          hour = $4.to_i
          minutes = $5.to_i
          seconds = $6.to_i
          create_time = Time.mktime(year,month,day,hour,minutes,seconds)
          sec_left =  time - (time_now.to_i - create_time.to_i)
          minutes = sec_left.to_i/60
          hours = minutes / 60
          days = hours / 24
          days = days+1
          if days > 0
            hours = hours % 24 
            minutes = minutes % 60
            if days > 1
              @time_left << days.to_s+" days"
            else
              @time_left << days.to_s+" day"
            end
#          elsif hours > 0
#            minutes = minutes % 60 
#            @time_left << hours.to_s+"h : "+minutes.to_s+"m"
#          else 
#            @time_left << minutes.to_s+"m" 
#          end
          else
            @time_left << "today"
          end
        end                                          
      end
    end
  end

  def deleteOldJobs
    jobs_email = params[:email][:email]
    if !params[:jobs].nil?
      params[:jobs].each do |box|
        no = box[0]
        value = box[1]
        if value.size > 1  #if not marked it should be "0"
          jobid = value
          rax = Raxml.find(:first,:conditions => ["jobid = #{jobid}"])
          Raxml.destroy(rax.id)
          command = "rm -r #{RAILS_ROOT}/public/jobs/#{jobid}"
          system command
        end
      end
    end
    redirect_to :action => "allJobs" , :email =>  "#{jobs_email}"

  end

  
  def contact
    getInfo
    @error = ""
    if !(params[:id].nil?)
      @error = "An error occurres, please try again!"
    end
  end

  def sendMessage
    name = params[:con_name]
    name = name.gsub(/\s/,"__")
    email = params[:con_email]
    subject = params[:con_subject]
    subject = subject.gsub(/\s/,"__")
    subject = subject.gsub(/\"/,"\\\"")
    subject = subject.gsub(/\'/,"\\\\\'")
    message = params[:con_message]
    message = message.gsub(/\n/,"#n#")
    message = message.gsub(/\s/,"__")
    message = message.gsub(/\"/,"\\\"")
    message = message.gsub(/\'/,"\\\\\'")
    if Raxml.sendMessage(name,email,subject,message)
      redirect_to :action => "confirmation"
    else
      redirect_to :action => "contact", :id=>1
    end
  end

  def confirmation
    getInfo
  end

  def about
    getInfo
  end

 
end
