module Daikon
  class Client
    include Bus

    EXCEPTIONS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  EOFError,
                  JSON::ParserError]

    attr_accessor :redis, :logger, :config

    def initialize(config = Daikon::Configuration.new, logger = nil)
      self.config  = config
      self.logger  = logger

      log "Started Daikon v#{VERSION}"
    end

    def connect
      EventMachine::Hiredis.connect(config.redis_url)
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
      options[:ssl] = {:verify_peer => true, :cert_chain_file => Daikon.data_dir("heroku.crt")}

      log "#{method.to_s.upcase} #{url}"

      http = EventMachine::HttpRequest.new(url).send(method, options)
      http.callback do
        log "SUCCESS: #{http.response}"
        emit(:request_success)
      end
      http.errback do
        log "ERROR: #{http.response}"
        emit(:request_error)
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

    def report_info(info)
       push :post, "/api/v1/infos.json", info
    rescue *EXCEPTIONS => ex
      exception(ex)
    end
  end
end
