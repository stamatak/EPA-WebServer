#!/usr/bin/ruby

class FastaFileParser
  attr_reader :seqs
  def initialize(file)
    @seqs = Hash.new
    f = File.open(file,'r')
    lines = f.readlines
    name = nil
    lines.each do |line|
      if line =~ />\s*(.+)/
        name = $1.gsub(/\s/,"_")
        @seqs[name] = ""
      elsif line =~/(\w+)/
        seq = $1
        @seqs[name] = @seqs[name]+seq
      end
    end
    puts seqs.size
    @seqs.each_key do |key|
      if (!@seqs[key].nil?) && (@seqs[key].size < 2)
        puts "Warning: Query sequence #{key} has less than 2 letters and will be ignored!"
        @seqs.delete(key)
      end
    end
  end

end

