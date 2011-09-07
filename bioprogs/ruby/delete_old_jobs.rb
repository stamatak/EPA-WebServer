#!/usr/bin/ruby


RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require "#{File.dirname(__FILE__)}/../../config/environment.rb"
require "#{RAILS_ROOT}/app/models/raxml.rb"
SERVER_NAME = ENV['SERVER_NAME']

#Checks the database for jobs that are older than @time. The expired entries are deleted and the corresponding Job directories deleted from the harddrive.
class DeleteOldJobs

  def initialize
    @time = 60*60*24*7*2 # 2 weeks ,set time here
    time = Time.new
    current = time.to_i
    create_time = nil
    saved = 0
    deleted = 0
    del = "{"

    raxmls = Raxml.find(:all)
    saved = raxmls.size
    raxmls.each do |entry|
      e  =   entry.created_at.to_s
      if  e =~ /(\d+)-(\d+)-(\d+)\s*(\d+):(\d+):(\d+)/
        year = $1.to_i
        month = $2.to_i
        day = $3.to_i
        hour = $4.to_i
        minutes = $5.to_i
        seconds = $6.to_i
        create_time = Time.mktime(year,month,day,hour,minutes,seconds)
        if time.to_i - create_time.to_i > @time  
          del = del+"#{entry.jobid}, "
          Raxml.destroy(entry.id)
          command = "rm -r #{RAILS_ROOT}/public/jobs/#{entry.jobid}"
          puts command
          system command
          deleted = deleted+1
        else
         
        end
      else
        raise "ERROR: could not parse time #{entry.created_at}!"
      end
    end
    puts "Deleted #{deleted} of #{saved} jobs"
    puts del+"}"
  end

end

DeleteOldJobs.new
