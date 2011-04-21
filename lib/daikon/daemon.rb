module Daikon
  class Daemon
    INFO_INTERVAL    = ENV["INFO_INTERVAL"] || 10
    SUMMARY_INTERVAL = ENV["SUMMARY_INTERVAL"] || 60

    def self.start(argv, ontop = false)
      Daemons.run_proc("daikon", :ARGV => argv, :log_output => true, :backtrace => true, :ontop => ontop) do
        config = Daikon::Configuration.new(argv)

        if argv.include?("-v") || argv.include?("--version")
          puts "Daikon v#{VERSION}"
          return
        end

        if argv.include?("run")
          logger = Logger.new(STDOUT)
        else
          logger = Logger.new("/tmp/radish.log")
        end

        client = Daikon::Client.new
        client.setup(config, logger)

        EventMachine::run do
          hiredis   = EventMachine::Hiredis.connect
          himonitor = EventMachine::Hiredis.connect

          himonitor.monitor do |line|
            Daikon::Monitor.parse(line)
          end

          EventMachine::add_periodic_timer(10) do
            hiredis.info do |info|
              client.report_info info
            end
          end

          EventMachine::add_periodic_timer(60) do
            client.report_summaries
          end
        end
      end
    end
  end
end
