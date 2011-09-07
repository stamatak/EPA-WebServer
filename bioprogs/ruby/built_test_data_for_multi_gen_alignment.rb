#!/usr/bin/ruby

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require "#{File.dirname(__FILE__)}/../../config/environment.rb"
require 'phylip_file_parser'


class BuiltTestDataForMultiGenAlignment

  def initialize(alifile, treefile, parfile,  seqs_for_test)
    @parfile = parfile
    @treefile = treefile
    command = "#{RAILS_ROOT}/bioprogs/raxml/raxmlHPC-SSE3 -s #{alifile} -m GTRGAMMA -p 12345 -n T1 -fs -t #{treefile} -q #{parfile}"
    system command
    gene = nil
    read_pool = []
    Dir.glob(alifile+".GENE.*"){|genefile|
      gene = PhylipFileParser.new(genefile)
      read_pool.concat(gene.extractSeqs!(seqs_for_test.to_i,"fasta"))
    }
    @queryfile = alifile+"#{seqs_for_test}_extracted_reads.fas"
    @new_alifile = alifile+"-#{seqs_for_test}.phy"
    writeArrayToFile(read_pool,@queryfile)
    gene = PhylipFileParser.new(alifile)
    gene.extractSeqs!(seqs_for_test.to_i,"fasta")
    writeHashToFile(gene.seqs,@new_alifile)
    testMapping
  end

  def writeArrayToFile(array,filename)
    out = File.open(filename,'w')
    array.each {|a| out.write(a)}
    out.close
  end

  def writeHashToFile(hash,filename)
    out = File.open(filename,'w')
    hash.each_key do |k| 
      out.write("#{hash.size} #{hash[k].size}\n")
      break
    end
    hash.each_key do |k| 
      out.write(k+" "+hash[k]+"\n")
    end
    out.close
  end

  def testMapping
    @id = "000000000"
    @jobpath = "/home/denis/work/RAxMLWS/public/jobs/#{@id}/"
    command =  "/home/denis/work/RAxMLWS/bioprogs/ruby/raxml_and_send_email.rb -link http://lxexelixis1.informatik.tu-muenchen.de:3000/raxml/results/#{@id}  -m GTRGAMMA    -n #{@id}  -f y  -s #{@new_alifile}   -t #{@treefile} -q #{@parfile}  -id #{@id} -useQ #{@queryfile} -mga -test_mapping"
    puts command 
    system command
  end


end

# multiGenAlignmentFile= ARGV[0]
# reference tree file = ARGV[1]
# partition file = ARGV[2]
#number of sequences used for the query pool = ARGV[3]

BuiltTestDataForMultiGenAlignment.new(ARGV[0], ARGV[1] , ARGV[2], ARGV[3])
