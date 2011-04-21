module Daikon
  class Client
    EXCEPTIONS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  EOFError,
                  JSON::ParserError,
                  Excon::Errors::SocketError]

    attr_accessor :redis, :logger, :config, :http, :monitor

    def setup(config, logger = nil)
      self.config  = config
      self.logger  = logger
      self.redis   = connect
      self.monitor = Monitor.new(connect, logger)
      self.http    = Excon.new(config.server_prefix)

      log "Started Daikon v#{VERSION}"
    end

    def connect
      Redis.connect(:url => config.redis_url)
    end

    def start_monitor
      monitor.start
    end

    def log(message)
      logger.info message if logger
    end

    def exception(error)
      log error.to_s
      error.backtrace.each do |line|
        log line
      end
    end

    def request(method, path, options = {})
      options[:method]  = method.to_s.upcase
      options[:path]    = path
      options[:headers] ||= {}
      options[:headers]['Authorization'] = config.api_key

      log "#{options[:method]} #{config.server_prefix}#{options[:path]}"
      http.reset
      http.request(options)
    end

    def push(method, path, body)
      json = body.to_json
      request(method, path,
                   :body    => json,
                   :headers => {"Content-Length" => json.size.to_s,
                                "Content-Type"   => "application/json"})
    end

    def rotate_monitor(start, stop)
      Daikon::Monitor.pop do |summary|
        summary["start"] = start
        summary["stop"] = stop

        push :post, "/api/v1/summaries.json", summary
      end
    rescue *EXCEPTIONS => ex
      exception(ex)
    end

    def report_info
       push :post, "/api/v1/infos.json", redis.info
    rescue *EXCEPTIONS => ex
      exception(ex)
    end
  end
end
