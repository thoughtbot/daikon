module Daikon
  class Client
    include NamespaceTools

    attr_accessor :redis, :logger, :config

    def setup(config, logger)
      self.config = config
      self.logger = logger
      self.redis  = Redis.new(:port => config.redis_port)

      logger.info "Started Daikon v#{VERSION}"
    end

    def fetch_commands
      logger.info "fetch commands and run them"
    end

    def send_info
      logger.info "sending INFO"
    end

    def rotate_monitor
      logger.info "wrap up and truncate monitor log"
    end

    def evaluate_redis(command)
      # Attempt to parse the given command string.
      argv =
        begin
          Shellwords.shellwords(command.to_s)
        rescue Exception => e
          STDERR.puts e.message
          e.backtrace.each {|bt| STDERR.puts bt}
          return { "error" => e.message }
        end
      return { "error" => "No command received." } unless argv[0]

      begin
        { "response" => execute_redis(argv) }
      rescue Exception => e
        STDERR.puts e.message
        e.backtrace.each {|bt| STDERR.puts bt}
        { "error" => e.message }
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
