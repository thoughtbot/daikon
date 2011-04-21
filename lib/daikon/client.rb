module Daikon
  class Client
    EXCEPTIONS = [Timeout::Error,
                  Errno::EINVAL,
                  Errno::ECONNRESET,
                  EOFError,
                  JSON::ParserError,
                  Excon::Errors::SocketError]

    attr_accessor :logger, :config, :http

    def setup(config, logger = nil)
      self.config  = config
      self.logger  = logger
      self.http    = Excon.new(config.server_prefix)

      log "Started Daikon v#{VERSION}"
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

    def report_summaries
      Daikon::Monitor.pop do |summary|
        require 'pp'
        pp summary
        report_summary(summary)
      end
    end

    def report_summary(summary)
      push :post, "/api/v1/summaries.json", summary
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
