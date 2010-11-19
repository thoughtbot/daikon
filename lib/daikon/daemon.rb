module Daikon
  class Daemon
    def self.start
      Daemons.run_proc('daikon') do
        logger = Logger.new("/tmp/radish.log")
        client = Daikon::Client.new(logger)
        config = Daikon::Configuration.new(Daemons.group.app_argv)

        loop do
          client.every

          sleep 1
        end
      end
    end
  end
end
