module Daikon
  class Daemon
    def self.start
      if ARGV.include?("run")
        logger = Logger.new(STDOUT)
      else
        logger = Logger.new("/tmp/radish.log")
      end

      config = Daikon::Configuration.new(ARGV)
      client = Daikon::Client.new
      client.setup(config, logger)
      client.start_monitor

      Daemons.run_proc('daikon') do
        count = 0

        loop do
          if count % 5 == 0
            client.report_info
          end

          client.fetch_commands

          if count % 10 == 9
            client.rotate_monitor
          end

          count += 1
          sleep 1
        end
      end
    end
  end
end
