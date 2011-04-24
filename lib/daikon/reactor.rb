module Daikon
  class Reactor
    attr_reader :current_time
    attr_writer :callback, :info_interval

    def initialize(client = nil)
      @client = client
    end

    def start
      EventMachine.add_periodic_timer(info_interval) do
        @current_time = Time.now
        collect_info
        callback
      end
    end

    def collect_info
      info_collector.info do |info|
        @client.report_info(info)
        callback
      end
    end

    private

    def callback
      if @callback && @callback.call(self)
        EventMachine.stop
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
  end
end
