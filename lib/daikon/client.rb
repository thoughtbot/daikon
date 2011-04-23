module Daikon
  class Client
    EXCEPTIONS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  EOFError,
                  JSON::ParserError]

    attr_accessor :redis, :logger, :config, :monitor

    def setup(config, logger = nil)
      self.config  = config
      self.logger  = logger
      self.redis   = connect
      self.monitor = Monitor.new

      log "Started Daikon v#{VERSION}"
    end

    def connect
      Redis.connect(:url => config.redis_url)
    end

    def start_monitor
      Monitor.start
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
      url = "#{config.server_prefix}#{path}"
      options[:head] ||= {}
      options[:head]['Authorization'] = config.api_key

      log "#{method} #{options[:url]}"

      EventMachine.run_block do
        http = EventMachine::HttpRequest.new(url).send(method, options)
        http.callback do
          log "=> #{http.response}"
        end
      end
    end

    def push(method, path, body)
      json = body.to_json
      request(method, path,
                   :body => json,
                   :head => {"Content-Length" => json.size.to_s,
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
