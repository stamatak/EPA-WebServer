#!/usr/bin/ruby

class PhyloXMLParser
  attr_reader :right_format

  def initialize(file)
    sleep 60
    f = File.open(file,'r')
    @data = f.readlines
    puts "# "+file
    @right_format =  checkFormat
  end

  def checkFormat
    clades_open = 0
    clades_closed = 0
    formated = ""
    if !(@data[0].chomp.eql?("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
      return false
    end
    @data.each do |line|
      while line =~ /<clade/ 
        line = line.sub(/<clade/,"")
        clades_open = clades_open+1
      end
      while line =~ /<\/clade>/
        line = line.sub(/<\/clade>/,"")
        clades_closed = clades_closed+1
      end
      formated = line
    end
    return clades_open == clades_closed
  end
end

