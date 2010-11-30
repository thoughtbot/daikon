module Daikon
  class Daemon
    def self.start(argv)
      config = Daikon::Configuration.new(argv)

      if argv.include?("-v") || argv.include?("--version")
        puts "Daikon v#{VERSION}"
        return
      end

      Daemons.run_proc("daikon", :log_output => true, :backtrace => true) do
        if argv.include?("run")
          logger = Logger.new(STDOUT)
        else
          logger = Logger.new("/tmp/radish.log")
        end

        count  = 0
        client = Daikon::Client.new
        client.setup(config, logger)
        client.start_monitor

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
