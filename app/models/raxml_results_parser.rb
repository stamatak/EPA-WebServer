class RaxmlResultsParser

  attr_reader :data ,:names, :files

  def initialize(file_ending)
    @job_id = file_ending
    @data = []
    @names = []
    @files = []
    getFiles
  end

  def getFiles
    Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/RAxML_*"){|file| 
      @files << file
      if file =~ /.+\/(RAxML_.+)\.#{@job_id}(.*)$/
        @names << $1+$2
      end
    }
    Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/alignment_file*"){|file| 
      if file =~ /.+\/(alignment_file.*)$/
        @files << file
        @names << $1
      end
    }
    Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/partition_file*"){|file| 
      if file =~ /.+\/(partition_file.*)$/
        @files << file
        @names << $1
      end
    }

    Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/queryfile*"){|file| 
      if file =~ /.+\/(queryfile.*)$/
        @files << file
        @names << $1
      end
    }
    
     Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/cluster*"){|file| 
      if file =~ /.+\/(cluster.*)$/
        @files << file
        @names << $1
      end
    }

    Dir.glob("#{RAILS_ROOT}/public/jobs/#{@job_id}/*.phyloxml"){|file| 
      if file =~ /.+\/([\w_]+.phyloxml)$/
        @files << file
        @names << $1
      end
    }

    @files << "#{RAILS_ROOT}/public/jobs/#{@job_id}/tree_file"
    @names << "input_tree"


    
  end

end
