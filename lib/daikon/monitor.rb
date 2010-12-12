module Daikon
  class Monitor
    attr_accessor :queue

    NEW_FORMAT        = /^(\d+\.\d+)( "[A-Z]+".*)/i
    OLD_SINGLE_FORMAT = /^(QUIT|RANDOMKEY|DBSIZE|EXPIRE|TTL|SAVE|BGSAVE|SHUTDOWN|BGREWRITEAOF|INFO|MONITOR|SLAVEOF)$/i
    OLD_MORE_FORMAT   = /^[A-Z]+ .*$/i

    def initialize(redis = nil, logger = nil)
      @queue  = []
      @redis  = redis
      @logger = logger
    end

    def start
      Thread.new do
        @redis.monitor do |line|
          parse(line)
        end
      end
    end

    def rotate
      @queue.shift(@queue.size)
    end

    def parse(line)
      if line =~ NEW_FORMAT
        timestamp = $1
        line      = $2.strip
        @queue.push({:at => Time.at(*timestamp.split('.').map(&:to_i)), :command => line})
      elsif line =~ OLD_SINGLE_FORMAT || line =~ OLD_MORE_FORMAT
        @queue.push({:at => Time.now, :command => line.strip})
      end
    end
  end
end
