class Reformat
  
attr_reader :data, :format
attr_accessor :format

  def initialize(file)
    f = File.open(file,'r')
    @data = f.readlines
    @format = "unk"
    detectFormat
    f.close
  end

  def detectFormat #Auto_detection
    i = 0
    while i < @data.size
      if @data[i] =~ /^>/ #Fasta format
        while  i < @data.size
          if @data[i] =~ /^>/
            i = i+1
            while i < @data.size && @data[i]=~/^[A-Za-z\-]+$/
              i = i+1
            end
          else
            return
          end
        end
        @format = "fas"

      elsif @data[i] =~ /^\s*(\d+)\s+(\d+)\s*$/ #Phylip format
        data = []
        data[0] = @data[i]
        start = i+1
        i = i+1
        seqs = $1.to_i
        real_seqs = 0
        len = $2.to_i
        j = 1
        while i <  @data.size
          if @data[i] =~ /^(\S+)\s+([A-Za-z\-\s]+)/
            data[j] = $1+" "+$2.gsub(/\s/,"")
            j = j+1
          elsif @data[i] =~ /^\s*([A-Za-z\-\s]+)/
            data[j] = data[j]+@data[i].gsub(/\s/,"")   # convert to a unsplitted format 
            j = j+1
          end
          if j > seqs
            j = 1
          end
          i = i+1
        end
        @data = data
        i = 1
        while i < @data.size
          #puts @data[i]
          if @data[i] =~ /^\S+\s+([A-Za-z\-\s]+)/
            real_seqs = real_seqs+1
            seqline = $1
            
            if len != seqline.length
              puts ("#{len}|#{seqline.gsub(/\s/,'').length}")
              return
            end
          elsif @data[i] =~ /^\s*$/
            
          else 
            return
          end
          i = i+1
        end
        if real_seqs == seqs
          @format = "phy"
        end
      elsif @data[i] =~ /^\s*#\s*Stockholm\s*\d+\.\d+\s*$/i #Stockholm format
        i = i+1
        while i < @data.size
          if !(@data[i] =~ /^\S+\s+[a-zA-Z\-\.]+\s*$/ || @data[i] =~ /^#=/ || @data[i] =~/^\s*$/ || @data[i] =~ /^\s*\/\/\s*$/)
            puts @data[i]
            return
          end
          i = i+1
        end
        @format = "sto"

      elsif @data[i] =~ /^\s*$/ #Blank lines are ignored
        i = i+1
        next
      else
        return
      end
    end
  end
  
  def reformatToStockholm
    supported = ["phy"]
    i = 0

    if @format.eql?("phy")
      while i < @data.size
        if @data[i] =~ /^\s*\d+\s+\d+\s*$/
          @data[i] = "# STOCKHOLM 1.0"
          @format = "sto"
          break
        end
        i = i+1
      end
      @data << "//"
    else
      message =  "Cannot convert #{@format} to Stockholm format! Following formats a supported:"
      supported.each {|s| message = message+" "+s}
      raise message
    end
  end

  def reformatToPhylip
    supported = ["fas","sto"]
    i = 0

    if @format.eql?("fas")
      phylip = []
      (names, seqs, lens,rows) = readfa(@data)
      max_name = names.map{ |n| n.length }.max
      phylip << "#{names.size} #{lens[0]}"
      names.each do |name|
        phylip << "#{pad_right(max_name + 1, name)}#{seqs[name]}" 
      end
      @data = phylip
      @format = "phy"
      
    elsif @format.eql?("sto")   
      seqs = Hash.new
      local_names = Hash.new
      names = []
      phylip = []
      len = nil
      maxnlen = 0
      i = 0
      while i < @data.size 
        line = @data[i]
        if  !( line =~ /^#/) && line =~ /^(\S+)\s+(\S+)\s*$/
          name = $1
          seq = $2
          name.gsub!(/\|\*\|/, "\\|\\*\\|")
          if @data[i+1] =~/^#=GR\s#{name}/  # in case there are reads that have the same name as the alignment sequences
            name = name+"_GR_1"
            if local_names[name].nil?
              local_names[name] = 1
            else
              if name =~/(.+GR_)(\d+)/
                n = local_names[name]+1
                local_names[name] =  n
                name = $1+(n).to_s
                local_names[name] =  n
              else
                raise "Error"
              end
            end
              
            if seqs[name].nil?
              seqs[name] = seq.gsub( /\./, "-" )
              names << name
            else
              seqs[name] = seqs[name]+seq.gsub( /\./, "-" )
            end
          elsif seqs[name].nil?
            seqs[name] = seq.gsub( /\./, "-" )
            names << name
          else
            seqs[name] = seqs[name]+seq.gsub( /\./, "-" )
          end
          maxnlen = [maxnlen, name.length].max
        elsif line =~ /^\s+$/
          local_names = Hash.new
        end
        i+=1
      end
     # seqs.each_key do |key|
     #   puts "#{key} => #{seqs[key].length} : #{seqs.size}"
     # end
      seqs.each_key do |key|
     #   puts "#{len} : #{seqs[key].length}"
        if len.nil?
          len = seqs[key].length
        elsif len != seqs[key].length
          raise "not equal seq lengths"
        end
      end
          
      phylip << "#{names.size} #{len}"
      names.each do |n|
        phylip <<( "#{n}#{" " * (maxnlen + 1 - n.length)}#{seqs[n]}")
      end
      @data = phylip
      @format = "phy"

    else
      message =  "Cannot convert #{@format} to Phylip format! Following formats a supported:"
      supported.each {|s| message = message+" "+s}
      raise message
    end
  end

  def writeToFile(file)
    f = File.open(file,'wb')
    @data.each {|line| f.write(line+"\n")}
    f.close
  end

  def exportClusterRepresentatives!
    reps = []
    if @format.eql?("fas")
      i = 0
      while  i < @data.size
        if @data[i] =~ /^(>\d+\|\*\|.*)\s{0,1}/  #reps are marked by |*|
          reps << $1
          i = i+1
          while @data[i]=~/^([A-Za-z\-]+)\s*$/
            reps << $1
            i = i+1
          end
          next
        end
        i = i+1
      end
      @data =  reps
    else
      raise "Data has wrong format for this function!"
    end
  end

######################
### Helper Methods ###
  private
  def readfa(fh)
    rows = 0
    names = []
    seqs = {}
    lens = []
    curname = nil
    curseq = nil
    minlen = 1000000
    maxlen = -1
    
    fh.each do |line|
      name = nil
      data = nil
      if line =~ />\s*(\S+)/
        if( curseq != nil )
          seqs[curname] = curseq;
          names << curname;
          lens << curseq.length
        end
        rows += 1
        curname = $1;
        curseq = ""
        
      elsif curname != nil
        line.gsub!( /\s/, "" )
        curseq += line
      end
    end
    
    seqs[curname] = curseq;
    names << curname;
    lens << curseq.length
    
    return [names, seqs, lens, rows];
  end
  
  private
  def pad_right( n, s )
    if( s.length < n )
      return s + (" " * (n - s.length))
    else
      return s;
    end
  end
  
end







