#!/usr/bin/ruby

require '~/work/RAxMLWS/app/models/raxml_treefile_parser'

class ParserTester

  def initialize(file)
    f = File.open(file, 'r')
    p = RaxmlTreefileParser.new(f)
    puts p.format
    puts p.valid_format
    puts p.error
  end

end

ParserTester.new(ARGV[0])
