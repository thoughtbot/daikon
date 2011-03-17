# More terrible overrides since the Daemons gem offers no way to override how
# its output is formatted.
module Daemons
  class Controller
    def print_usage_with_daikon_options
      print_usage_without_daikon_options
      puts "    -k 1234567890                    radishapp.com api key"
      puts "    -u redis://0.0.0.0:6379          redis URL to monitor"
    end

    alias_method :print_usage_without_daikon_options, :print_usage
    alias_method :print_usage, :print_usage_with_daikon_options
  end
end
