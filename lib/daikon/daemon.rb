module Daikon
  class Daemon
    INFO_INTERVAL    = ENV["INFO_INTERVAL"] || 5
    SUMMARY_INTERVAL = ENV["SUMMARY_INTERVAL"] || 60

    def self.sleep_time=(sleep_time)
      @@sleep_time = sleep_time
    end

    def self.sleep_time
      @@sleep_time ||= 1
    end

    def self.run=(run)
      @@run = run
    end

    def self.run
      @@run
    end

    def self.start(argv, ontop = false)
      self.run = true
      config = Daikon::Configuration.new(argv)

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

        rotated_at  = Time.now
        reported_at = Time.now
        client      = Daikon::Client.new

        client.setup(config, logger)
        client.start_monitor

        while self.run do
          now = Time.now

          if now - reported_at >= sleep_time * INFO_INTERVAL.to_i
            client.report_info
            reported_at = now
          end

          if now - rotated_at >= sleep_time * SUMMARY_INTERVAL.to_i
            client.rotate_monitor(rotated_at, now)
            rotated_at = now
          end

          sleep sleep_time
        end
      end
    end
  end
end
