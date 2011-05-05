module Daikon
  class Reactor
    include Bus
    attr_reader :current_time
    attr_writer :info_interval, :summary_interval

    def initialize(client = nil)
      @client = client
    end

    def start
      emit(:start)
      EventMachine.add_periodic_timer(info_interval) do
        emit(:start_info)
        @current_time = Time.now
        collect_info
        emit(:end_info)
      end

      EventMachine.add_periodic_timer(summary_interval) do
        emit(:start_summary)
        @current_time = Time.now
        @client.rotate_monitor(@current_time, @current_time)
        emit(:end_summary)
      end

      Daikon::Monitor.start(summary_collector)
      emit(:started)
    end

    def collect_info
      info_collector.info do |info|
        emit(:collect_info)
        @client.report_info(info)
        emit(:collected_info)
      end
    end

    def connect
      @client.connect
    end

    def info_collector
      @info_collector ||= connect
    end

    def info_interval
      @info_interval ||= 10
    end

    def summary_collector
      @summary_collector ||= connect
    end

    def summary_interval
      @summary_interval ||= 60
    end
  end
end
