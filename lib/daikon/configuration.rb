module Daikon
  class Configuration
    BLANK_KEY = "1234567890"
    FLAGS     = ["-u",                   "-k",      "-s"]
    OPTIONS   = ["redis_url",            "api_key", "server_prefix"]
    DEFAULTS  = ["redis://0.0.0.0:6379", BLANK_KEY, "https://radish.heroku.com"]

    attr_accessor *OPTIONS

    def initialize(argv = [])
      @argv = argv

      validate_deprecated_options
      parse
      validate_api_key
    end

    private

    def argv_matches?(regexp)
      @argv.any? { |arg| arg =~ regexp }
    end

    def validate_deprecated_options
      if argv_matches?(/\-h|\-p/)
        abort "Please use '-u redis://127.0.0.1:6379' format instead to specify redis url"
      end
    end

    def validate_api_key
      if api_key == BLANK_KEY && argv_matches?(/start|run/)
        abort "Must supply an api key to start the daemon.\nExample: daikon start #{FLAGS[2]} #{DEFAULTS[2]}"
      end
    end

    def parse
      FLAGS.each_with_index do |flag, flag_index|
        argv_index = @argv.index(flag)
        value = if argv_index
                  @argv[argv_index + 1]
                else
                  DEFAULTS[flag_index]
                end

        send "#{OPTIONS[flag_index]}=", value
      end
    end
  end
end
