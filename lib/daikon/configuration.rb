module Daikon
  class Configuration
    BLANK_KEY = "1234567890"
    URL       = "https://radish.heroku.com"
    FLAGS     = ["-u",                   "-k",      "-s"]
    OPTIONS   = ["redis_url",            "api_key", "server_prefix"]
    DEFAULTS  = ["redis://0.0.0.0:6379", BLANK_KEY, URL]

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
      if argv_matches?(/^(\-h|\-p)$/)
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
        option_variable_name = OPTIONS[flag_index]
        default_value = DEFAULTS[flag_index]
        current_value = send(option_variable_name)

        value = if argv_index
                  @argv[argv_index + 1]
                elsif yaml_config[option_variable_name]
                  yaml_config[option_variable_name]
                else
                  default_value
                end

        send "#{option_variable_name}=", value
      end
    end

    def yaml_config
      @yaml_config ||= begin
                         loaded_yaml = YAML.load_file('daikon.yml')
                         loaded_yaml['daikon']
                       rescue Errno::ENOENT
                         {}
                       end
    end
  end
end
