module Daikon
  class Server
    def self.start(logger, port)
      fork do
        require 'webrick'
        server = WEBrick::HTTPServer.new :Logger => logger, :Port => port
        server.mount_proc('/') do |req, resp|
          resp.body = <<-HTML
                <a href='http://radishapp.com'>Radish: Dig deep into Redis.</a>
                <br />
                Running Daikon v#{VERSION}
                HTML
        end
        trap('INT')  { server.stop }
        trap('TERM') { server.stop }
        server.start
      end
    end
  end
end
