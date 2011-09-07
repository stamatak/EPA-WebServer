class RaxmlPartitionfileParser

  attr_reader :data, :valid_format, :error, :matrices

  def initialize(*args)
    if args.size == 2  # args[0] = stream, args[1] = ali_length
      stream = args[0]
      ali_length = args[1]
      @filename = ""
      @data = []
      if stream.instance_of?(String) #because of testing
        if stream =~ /\S+\/(\w+\.phylip)$/
          @filename = $1
        end
        f = File.open(stream,'r')
        @data = f.readlines
        f.close
      else
        @filename = stream.original_filename
        @data = stream.readlines 
      end

      @valid_format = false
      @error  = ""
      @len = ali_length
      @occ = Array.new(@len,0)
      @matrices = []
      checkFormat
    else
      file = args[0]
      @filename = file
      f = File.open(file,'r')
      @data = f.readlines
      @valid_format = true
      @error  = ""
      @matrices = []
      getRaxmlModelParameters
    end
      
  end

  private
  def checkFormat
    n = 1
    reads = []
    @data.each do |line|
      if line =~ /^\s*$/
        
      elsif  line =~ /^([A-Z]+),\s+\S+\s+=(\s+\d+\s*-\s*\d+\s*,)*(\s+\d+\s*-\s*\d+\s*)$/ ||  line =~ /^([A-Z]+),\s+\S+\s+=(\s+\d+\s*-\s*\d+\\\d+,)*(\s+\d+\s*-\s*\d+\\\d+)$/
        @matrices << $1
        digits = line.scan(/\d+\-\d+/)
        digits.each do |dig|
          if dig =~/(\d+)\-(\d+)/
            if $1.to_i > @len || $2.to_i > @len
              @error = "Read position to long(Alignment length is #{@len})! \n ParserError :: #{@filename} line: #{n} => #{line}"
              return
            end
          end
        end
        if line =~ /^[A-Z]+,\s+\S+\s+=(\s+\d+-\d+,)*(\s+\d+-\d+)$/
          a = line.scan(/\d+\-\d+/)
          if line =~/(\d+)\-(\d+)/
            reads << [$1.to_i,$2.to_i]
          end
        end
      else
        @error = "Invalid partitionfile format! \n ParserError :: #{@filename} line: #{n} => #{line}"
        return
      end
      n = n+1
    end
    reads.each do |x,y|
      if !(occupy_sequence(x,y))
        @error = "Reads are not allowed to overlap! \n ParserError :: #{@filename}"
        return
      end
    end
    @valid_format = true
  end

  def occupy_sequence(i,j)
    i = i-1
    while i < j
      if @occ[i] == 1
        return false
      else
        @occ[i] = 1
      end
      i = i+1
    end
    return true
  end

  def getRaxmlModelParameters
    n = 0
    @data.each do |line|
      if line =~ /^\s*$/
        
      elsif  line =~ /^([A-Z]+),\s+\S+\s+=(\s+\d+-\d+,)*(\s+\d+-\d+)$/ ||  line =~ /^([A-Z]+),\s+\S+\s+=(\s+\d+-\d+\\\d+,)*(\s+\d+-\d+\\\d+)$/
        @matrices << $1
      else
        @error = "Invalid partitionfile format! \n ParserError :: #{@filename} line: #{n} => #{line}"
        return
      end
      n = n+1
    end
  end
end


