class FastaToPhylip
  
  attr_reader :phylip

  def initialize(fasta_data_array)
    @phylip = []
    puts "************************************"
    (names, seqs, lens,rows) = readfa(fasta_data_array)
    puts "****************************************"
    max_name = names.map{ |n| n.length }.max
    @phylip << "#{names.size} #{lens[0]}"
    names.each do |name|
      @phylip << "#{pad_right(max_name + 1, name)}#{seqs[name]}" 
    end

  end
  
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

  def pad_right( n, s )
    if( s.length < n )
      return s + (" " * (n - s.length))
    else
      return s;
    end
  end

end





