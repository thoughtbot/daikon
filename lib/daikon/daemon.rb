module Daikon
  class Daemon
    def self.start
      Daemons.run_proc('daikon') do
        if ARGV.include?("run")
          logger = Logger.new(STDOUT)
        else
          logger = Logger.new("/tmp/radish.log")
        end

        config = Daikon::Configuration.new(ARGV)
        client = Daikon::Client.new(config, logger)
        count  = 0

        logger.info "spawn monitor watcher"

        loop do
          client.fetch_commands

          if count % 5 == 4
            client.send_info
          end

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
