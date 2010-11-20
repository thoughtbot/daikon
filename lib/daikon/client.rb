module Daikon
  class Client
    include NamespaceTools

    attr_accessor :redis, :logger, :config, :http

    def setup(config, logger = nil)
      self.config = config
      self.logger = logger
      self.redis  = Redis.new(:port => config.redis_port)
      self.http   = Net::HTTP::Persistent.new
      http.headers['Authorization'] = config.api_key

      log "Started Daikon v#{VERSION}"
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

        http_request(:put, "api/v1/commands/#{id}.json") do |request|
          request.body = result.to_json
          request.add_field "Content-Length", request.body.size.to_s
          request.add_field "Content-Type",   "application/json"
        end
      end
    end

    def send_info
      log "sending INFO"
    end

    def rotate_monitor
      log "wrap up and truncate monitor log"
    end

    def evaluate_redis(command)
      # Attempt to parse the given command string.
      argv =
        begin
          Shellwords.shellwords(command.to_s)
        rescue Exception => e
          STDERR.puts e.message
          e.backtrace.each {|bt| STDERR.puts bt}
          return { "response" => e.message }
        end
      return { "response" => "No command received." } unless argv[0]

      begin
        { "response" => execute_redis(argv) }
      rescue Exception => e
        STDERR.puts e.message
        e.backtrace.each {|bt| STDERR.puts bt}
        { "response" => e.message }
      end
    end

    def namespace
      nil
    end

    def execute_redis(argv)
      # Apply the current namespace to any fields that need it.
      argv = namespace_input(namespace, *argv)

      # Issue the default help text if the command was not recognized.
      raise "I'm sorry, I don't recognize that command.  #{help}" unless argv.kind_of? Array

      if result = bypass(argv)
        result
      else
        # Send the command to Redis.
        result = redis.send(*argv)

        # Remove the namespace from any commands that return a key.
        denamespace_output namespace, argv.first, result
      end
    end

    def bypass(argv)
      queue = "transactions-#{namespace}"

      if argv.first == "multi"
        redis.del queue
        redis.rpush queue, argv.to_json
        return "OK"
      elsif redis.llen(queue).to_i >= 1
        redis.rpush queue, argv.to_json

        if %w( discard exec ).include? argv.first
          commands = redis.lrange(queue, 0, -1)
          redis.del queue

          return commands.map do |c|
            cmd = JSON.parse(c)

            # Send the command to Redis.
            result = redis.send(*cmd)

            # Remove the namespace from any commands that return a key.
            denamespace_output namespace, cmd.first, result
          end.last
        end

        return "QUEUED"
      end
    end
  end
end
