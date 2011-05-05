module Daikon
  module Bus
    def channel
      @channel ||= EM::Channel.new
    end
    private :channel

    def emit(event)
      channel.push(event)
    end

    def on(event, &block)
      channel.subscribe{ |msg| EM::Callback(msg, &block).call if event == msg }
    end
  end
end
