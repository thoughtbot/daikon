module Daikon
  class Daemon
    def self.start(argv, ontop = false)
      config = Configuration.new(argv)

      if argv.include?("-v") || argv.include?("--version")
        puts "Daikon v#{VERSION}"
        return
      end

      Daemons.run_proc("daikon", :ARGV => argv, :log_output => true, :backtrace => true, :ontop => ontop) do
        if argv.include?("run")
          logger = Logger.new(STDOUT)
        else
          logger = Logger.new("/tmp/radish.log")
        end

        client  = Client.new(config, logger)
        reactor = Reactor.new(client)

        EventMachine.run do
          reactor.start
        end
      end
    end
  end
end
