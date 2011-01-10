module Daikon
  class Configuration
    FLAGS    = %w[-h         -p         -k         -f       -s]
    OPTIONS  = %w[redis_host redis_port api_key    field_id server_prefix]
    DEFAULTS = %w[127.0.0.1  6379       1234567890 1        https://radish.heroku.com]

    attr_accessor *OPTIONS

    def initialize(argv = [])
      FLAGS.each_with_index do |flag, flag_index|
        argv_index = argv.index(flag)
        value = if argv_index
                  argv[argv_index + 1]
                else
                  DEFAULTS[flag_index]
                end

        send "#{OPTIONS[flag_index]}=", value
      end

      if api_key == DEFAULTS[2] && argv.any? { |arg| arg =~ /start|run/ }
        abort "Must supply an api key to start the daemon.\nExample: daikon start #{FLAGS[2]} #{DEFAULTS[2]}"
      end
    end
  end
end
