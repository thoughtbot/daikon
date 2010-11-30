module Daikon
  class Client
    include NamespaceTools

    EXCEPTIONS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  EOFError,
                  Net::HTTPBadResponse,
                  Net::HTTPHeaderSyntaxError,
                  Net::ProtocolError,
                  Net::HTTP::Persistent::Error,
                  JSON::ParserError]

    attr_accessor :redis, :logger, :config, :http, :monitor

    def setup(config, logger = nil)
      self.config = config
      self.logger = logger
      self.redis  = Redis.new(:host => config.redis_host, :port => config.redis_port)
      self.http   = Net::HTTP::Persistent.new
      http.headers['Authorization'] = config.api_key

      log "Started Daikon v#{VERSION}"
    end

    def start_monitor
      self.monitor = StringIO.new
      Thread.new do
        Redis.new(:port => config.redis_port).monitor do |line|
          monitor.puts line
        end
      end
    end

    def log(message)
      logger.info message if logger
    end

    def http_request(method, url)
      request_uri    = URI.parse("#{config.server_prefix}/#{url}")
      request_method = Net::HTTP.const_get method.to_s.capitalize
      request        = request_method.new request_uri.path

      yield request if block_given?

      log "#{method.to_s.upcase} #{request_uri}"
      http.request request_uri, request
    end

    def fetch_commands
      raw_commands = http_request(:get, "api/v1/commands.json")
      commands = JSON.parse(raw_commands.body)

      commands.each do |id, command|
        result = evaluate_redis(command)
        pretty = StringIO.new
        PP.pp(result, pretty)

        http_request(:put, "api/v1/commands/#{id}.json") do |request|
          request.body = {"response" => pretty.string.strip}.to_json
          request.add_field "Content-Length", request.body.size.to_s
          request.add_field "Content-Type",   "application/json"
        end
      end
    rescue *EXCEPTIONS => ex
      log ex.to_s
    end

    def report_info
      http_request(:post, "api/v1/info.json") do |request|
        request.body = redis.info.to_json
        request.add_field "Content-Length", request.body.size.to_s
        request.add_field "Content-Type",   "application/json"
      end
    rescue *EXCEPTIONS => ex
      log ex.to_s
    end

    def rotate_monitor
      monitor_data = monitor.string
      monitor.reopen(StringIO.new)

      http_request(:post, "api/v1/monitor") do |request|
        request.body = Gem.gzip(monitor_data)
        request.add_field "Content-Length", request.body.size.to_s
        request.add_field "Content-Type",   "application/x-gzip"
      end
    rescue *EXCEPTIONS => ex
      log ex.to_s
    end

    def evaluate_redis(command)
      # Attempt to parse the given command string.
      argv =
        begin
          Shellwords.shellwords(command.to_s)
        rescue Exception => e
          STDERR.puts e.message
          e.backtrace.each {|bt| STDERR.puts bt}
          return e.message
        end
      return "No command received." unless argv[0]

      begin
        execute_redis(argv)
      rescue Exception => e
        STDERR.puts e.message
        e.backtrace.each {|bt| STDERR.puts bt}
        e.message
      end
    end

    def namespace
      nil
    end

    def execute_redis(argv)
      # Apply the current namespace to any fields that need it.
      argv = namespace_input(namespace, *argv)

      raise "Not a Redis command." unless argv.kind_of? Array

      # Send the command to Redis.
      result = redis.send(*argv)

      # Remove the namespace from any commands that return a key.
      denamespace_output namespace, argv.first, result
    end
  end
end
