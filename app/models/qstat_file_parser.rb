#!/usr/bin/ruby 
class QstatFileParser

  attr_reader :slots, :used_slots
  def initialize(file)
    @slots = 0
    @used_slots = 0
    f = File.open(file,'r')
    lines  = f.readlines
    lines.each do |line|
      if line =~ /^\S+\s+\S+\s+\d+\/(\d+)\/(\d+)/
        @slots = $2.to_i
        @used_slots = $1.to_i
      end
    end
  end
end

