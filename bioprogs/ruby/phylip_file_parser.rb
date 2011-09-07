#!/usr/bin/ruby

class PhylipFileParser

  attr_reader :seqs
   
  def initialize(file)
    @seqs = Hash.new
    @gene = "";
    if file =~ /GENE\.(\d+)/
      @gene = $1
    end
    parse(file)
  end

  def parse(file)
    f = File.open(file)
    lines = f.readlines
    lines.each do |line|
      if line =~ /^\s*(\S+)\s+([A-Za-z\s\-]+)/
        taxa = $1
        seq = $2.gsub(/\s/,"")
        @seqs[taxa] = seq
      end
    end
  end

  def disalign!
    @seqs.each_key{|k|@seqs[k].gsub!(/\-/,"")}
  end

  def removeGaps!(key)
    @seqs[key].gsub!(/\-/,"")
  end

  def extractSeqs!(amount, format)
    extracted_seqs = []
    if amount > @seqs.size
      raise "ERROR: tried to extract to many sequences"
    elsif format.eql?("fasta")
      i = 1
      @seqs.each_key do |k|
        if i > amount
          break
        end
        removeGaps!(k)
        if @seqs[k].size > 0
          extracted_seqs << ">"+k+" GENE_#{@gene}"+"\n"+@seqs[k]+"\n"
        else
          puts k+"GENE_#{@gene}"
        end
        @seqs.delete(k)
          i = i+1

      end
    else
      raise "ERROR: some ERROR ocurred"
    end
      

    return extracted_seqs
    
  end

end
