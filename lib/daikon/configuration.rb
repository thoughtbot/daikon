module Daikon
  class Configuration
    FLAGS    = %w[-p         -k         -f       -s]
    OPTIONS  = %w[redis_port api_key    field_id server_prefix]
    DEFAULTS = %w[6379       1234567890 1        https://radishapp.com]

    attr_accessor *OPTIONS

    def initialize(argv)
      FLAGS.each_with_index do |flag, flag_index|
        argv_index = argv.index(flag)
        value = if argv_index
                  argv[argv_index + 1]
                else
                  DEFAULTS[flag_index]
                end

        send "#{OPTIONS[flag_index]}=", value
      end
    end
  end
end
