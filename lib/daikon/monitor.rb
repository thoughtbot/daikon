module Daikon
  class Monitor
    attr_accessor :queue

    NEW_FORMAT        = /^\+?(\d+\.\d+)( "[A-Z]+".*)/i
    OLD_SINGLE_FORMAT = /^(QUIT|RANDOMKEY|DBSIZE|EXPIRE|TTL|SAVE|BGSAVE|SHUTDOWN|BGREWRITEAOF|INFO|MONITOR|SLAVEOF)$/i
    OLD_MORE_FORMAT   = /^[A-Z]+ .*$/i

    def initialize(redis = nil, logger = nil)
      @queue  = []
      @redis  = redis
      @logger = logger
      @mutex  = Mutex.new
    end

    def start
      Thread.new do
        @redis.monitor do |line|
          parse(line)
        end
      end
    end

    def lock(&block)
      @mutex.synchronize(&block)
    end

    def rotate
      lock { @queue.shift(@queue.size) }
    end

    def parse(line)
      if line =~ NEW_FORMAT
        push(Float($1), $2)
      elsif line =~ OLD_SINGLE_FORMAT || line =~ OLD_MORE_FORMAT
        push(Time.now.to_f, line)
      end
    end

    def push(at, command)
      lock { @queue.push({:at => at, :command => command.strip}) }
    end
  end
end
