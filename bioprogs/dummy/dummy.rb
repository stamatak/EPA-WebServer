#!/usr/bin/ruby
#Dummy procedure 
class Dummy 

  def initialize(opts)
    @alifile = ""
    @outfile = ""
    @time = 20
    @speed =""
    @model =""

    @treefile
    @mp = 0.0
    @mc = 0.0

    optionsParser(opts)
  end

  def optionsParser(opts)
    help = []
    help << "*** Options ***\n"
    help << "-s <alifile> \n"
    help << "-n <outfile> \n"
    help << "-wait time to sleep \n"
    help << "-f y|v \n"
    help << "-m modelname \n" 
    help << "-t <treefile> \n"
    help << "-H float \n"
    help << "-G float \n"

    i = 0
    while i< opts.size
      if opts[i].eql?("-s")
        @alifile = opts[i+1]
        i = i+1
      elsif opts[i].eql?("-n")
        @outfile = opts[i+1]
        i = i+1
      elsif opts[i].eql?("-wait")
        @time = opts[i+1].to_i
        puts @time
        i = i+1
      elsif opts[i].eql?("-f")
        i = i+1
        if opts[i].eql?("y")
          @speed = "fast"
        elsif opts[i].eql?("v")
          @speed = "slow"
        else
          puts "ERROR: unknown option for -f"
        end
      elsif opts[i].eql?("-m")
        if opts[i+1] =~ /^PROT/
          @model = "#{opts[i+1]} #{opts[i+2]}"
          i = i+2
        else
          @model = opts[i+1]
          i = i+1
        end
      elsif opts[i].eql?("-t")
        @treefile = opts[i+1]
        i = i+1
      elsif opts[i].eql?("-H")
        @mp = opts[i+1].to_f
        i = i+1
      elsif opts[i].eql?("-G")
        @mc = opts[i+1].to_f
        i = i+1              
      elsif opts[i].eql?("--help")
        puts help
        exit
      else
        puts help
        puts opts
        puts "ERROR: unknown Option!"
        
      end
      i = i+1
    end
  end

  def execude
    sleep @time
    infile = File.open(@alifile,'r')
    data = infile.readlines
    infile.close
    outfile = File.open(@outfile,'w')
    data.each {|d| outfile.write(d)}
    outfile.close
  end
end


Dummy.new(ARGV).execude
