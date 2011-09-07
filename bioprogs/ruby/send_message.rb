#!/usr/bin/ruby

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
require 'net/smtp'
require "#{File.dirname(__FILE__)}/../../config/environment.rb"
SERVER_NAME = ENV['SERVER_NAME']

### Main script that handles the messages sent by the contact formular on the webpage. It gets four command line parameters, 
### -n name 
### -e email
### -s subject
### -m message (words connected by "__")

class SendMessage 

  def initialize(opts)
    @name =""
    @email =""
    @subject =""
    @message =""
    i = 0
    while i<opts.size
      if opts[i].eql?("-n")
        @name = opts[i+1]
        i = i+1
      elsif
        opts[i].eql?("-e")
        @email = opts[i+1]
        i = i+1
      elsif
        opts[i].eql?("-s")
        @subject = opts[i+1]
        i = i+1
      elsif opts[i].eql?("-m")
        @message = opts[i+1]
        i = i+1
      end
      i = i+1
    end
    if @name.eql?("")
      @name = "NONAME"
    else
      @name = @name.gsub(/\_\_/," ")
    end
    if @email.eql?("")
      @email = "NOEMAIL"
    end

    if @subject.eql?("")
      @subject= "Contact message from webserver with no subject."
    else
      @subject = @subject.gsub(/\_\_/," ")
    end
    @message = @message.gsub(/\_\_/," ")
    @message =  @message.gsub(/\#n\#/,"\n")
    @email_address1 = "Denis.Krompass@campus.lmu.de"
    @email_address2 = "stamatak@in.tum.de"
    @email_address3 = "bergers@in.tum.de"
    @email_address4 = "raxml@h-its.org"
    send_email
    
  end
  ## send email to @email_addressesX, (Alexi,Simon,Denis)
  def send_email
    Net::SMTP.start(ENV['MAIL_SENDER'], 25) do |smtp|
      smtp.open_message_stream("#{ENV['SERVER_NAME']}", @email_address4,@email_address1,@email_address3) do |f|
        
        f.puts "From: RAxMLWS.Contact"
        
        f.puts "To: #{@email_address}"

        f.puts "Subject: RAxML Webserver message: #{@subject}"
        
        f.puts "#{@name} (#{@email}) sent following message:\n #{@message}"
      end
    end
  end
end

SendMessage.new(ARGV)
