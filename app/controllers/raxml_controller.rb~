class RaxmlController < ApplicationController

  def index
    @dna_model_options = ""
    models = ["GTRGAMMA","GTRCAT"]
    models.each {|m| @dna_model_options= @dna_model_options+"<option>#{m}</option>"}
    @aa_model_options = ""
    models = ["PROTGAMMA","PROTCAT"]
    models.each {|m| @aa_model_options= @aa_model_options+"<option>#{m}</option>"}
    @aa_matrices = ""
    matrices = ["DAYHOFF", "DCMUT", "JTT", "MTREV", "WAG", "RTREV", "CPREV", "VT", "BLOSUM62", "MTMAM", "LG", "GTR"]
    matrices.each {|m| @aa_matrices= @aa_matrices+"<option>#{m}</option>"}
    @heuristics =""
    heuristics = ["none","MP","MC"]
    heuristics.each {|h| @heuristics = @heuristics+"<option>#{h}</option>"}
  end

  def submitJob    
    @direcrory = nil
    
    @query = params[:query]
    @speed = params[:speed]
    @substmodel = ""
    @matrix = nil
    @sm_float = nil
    if @type.eql?("DNA")
      @substmodel = "#{params[:dna_substmodel]}"
    else
      @substmodel = params[:aa_substmodel]
      @matrix = params[:matrix]
      @sm_float = params[:sm_float][:smf]
      @substmodel = "#{@substmodel} #{@matrix} #{@sm_float}"
    end
    
    @heuristic = params[:heuristic]
    @heu_float = "" 
    if @heuristic.eql?("none")
      @heu_float = params[:heufloat]
    end
    @heuristic = @heuristic+" "+@heu_float

    @wait = params[:wait][:time]
    @email = params[:email][:e]
    @outfile = ""
    @alifile = ""
    @pid = 0

    rax = Raxml.new({ :alifile => @alifile, :query => @query, :outfile => @outfile, :speed => @speed, :substmodel => @substmodel, :heuristic => @heuristic, :treefile => @treefile, :email => @email, :pid => @pid, :wait => @wait})
    rax.save
    
    buildJobDir(rax)

    @alifile = saveInfile(params[:upload][:upfile])
    rax.update_attribute(:alifile,@alifile)
    rax.update_attribute(:outfile,@directory+"results.txt")

    if !(params[:treefile][:file].nil?)
      @treefile = saveInfile(params[:treefile][:file])
      rax.update_attribute(:treefile,@treefile)
    end

    link = url_for :controller => 'raxml', :action => 'results', :id => rax.id
    rax.execude(link)
    redirect_to :action => 'wait', :id => rax.id 
  end

  def buildJobDir(rax)
    @directory = "#{RAILS_ROOT}/public/jobs/#{rax.id}/"
    Dir.mkdir(@directory) rescue system("rm -r #{@directory}; mkdir #{@directory}")
  end

  def saveInfile(stream)
    file = @directory+stream.original_filename
    File.open(file, "wb") { |f| f.write(stream.read) }
    return file
  end
   
  def wait
    rax = Raxml.find_by_id(params[:id])
    if pidAlive?(rax.pid)
      render :action => "wait"
    else
      redirect_to :action => "results" , :id => rax.id
    end
  end

  def pidAlive?(pid)
    Process.kill(0, Integer(pid))
    return true
  rescue 
    return false
  end

  def results
    rax = Raxml.find_by_id(params[:id])    
#    if rax.emailValid?
#      sendEmail(rax.email,rax.id)
#    end
    @results =  RaxmlResultsParser.new(rax.outfile).data
  end

  def sendEmail(recipient,id) ### not in use
    subject = "Your RAxML job has been finished"
    link = url_for :controller => 'raxml', :action => 'results', :id => id
    Emailer.deliver_email(recipient, subject, link)
    return if request.xhr?
  end
  
  def saveEmail ### not in use
    rax = Raxml.find_by_id(params[:id])
    rax.update_attribute(:email, params[:email][:e])
    redirect_to :action => 'wait' , :id => params[:id]
  end
end
