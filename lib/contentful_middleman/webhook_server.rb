require 'open-uri'
require 'thread'
require 'webrick'
require 'stringio'

module ContentfulMiddleman
  class ReceiveController < WEBrick::HTTPServlet::AbstractServlet
    def respond(request, response)
      system("bundle exec middleman contentful --rebuild")

      response.body = ""
      response.status = 200
    end

    alias :do_GET :respond
    alias :do_POST :respond
  end

  class WebhookServer
    PORT = 5678

    def self.start
      puts "Webhook server starting at: http://#{get_public_ip}:#{PORT}"
      Thread.new { WebhookServer.new.start }
    end

    def self.get_public_ip
      require 'open-uri'
      open('http://whatismyip.akamai.com').read
    end

    def start
      @server = WEBrick::HTTPServer.new(:Port => PORT, :AccessLog => [], :Logger => WEBrick::Log::new("/dev/null", 7))
      @server.mount "/receive", ReceiveController

      @server.start
    end
  end
end
