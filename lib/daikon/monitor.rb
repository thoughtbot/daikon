module Daikon
  class Monitor
    NO_ARG_COMMANDS = ["BGREWRITEAOF", "BGSAVE", "CONFIG RESETSTAT", "DBSIZE", "DEBUG SEGFAULT", "DISCARD", "EXEC", "FLUSHALL", "FLUSHDB", "INFO", "LASTSAVE", "MONITOR", "MULTI", "PING", "QUIT", "RANDOMKEY", "SAVE", "SHUTDOWN", "SYNC", "UNWATCH"]
    READ_COMMANDS   = ["EXISTS", "GET", "GETBIT", "GETRANGE", "HEXISTS", "HGET", "HGETALL", "HKEYS", "HLEN", "HMGET", "HVALS", "KEYS", "LINDEX", "LLEN", "LRANGE", "MGET", "SCARD", "SDIFF", "SINTER", "SISMEMBER", "SMEMBERS", "SORT", "SRANDMEMBER", "STRLEN", "SUNION", "TTL", "TYPE", "ZCARD", "ZCOUNT", "ZRANGE", "ZRANGEBYSCORE", "ZRANK", "ZREVRANGE", "ZREVRANGEBYSCORE", "ZREVRANK", "ZSCORE"].to_set
    WRITE_COMMANDS  = ["APPEND", "BLPOP", "BRPOP", "BRPOPLPUSH", "DECR", "DECRBY", "DEL", "GETSET", "EXPIRE", "EXPIREAT", "HDEL", "HINCRBY", "HMSET", "HSET", "HSETNX", "INCR", "INCRBY", "LINSERT", "LPOP", "LPUSH", "LPUSHX", "LREM", "LSET", "LTRIM", "MOVE", "MSET", "MSETNX", "PERSIST", "RENAME", "RENAMENX", "RPOP", "RPOPLPUSH", "RPUSH", "RPUSHX", "SADD", "SDIFFSTORE", "SET", "SETBIT", "SETEX", "SETNX", "SETRANGE", "SINTERSTORE", "SMOVE", "SPOP", "SREM", "SUNIONSTORE", "ZADD", "ZINCRBY", "ZINTERSTORE", "ZREM", "ZREMRANGEBYRANK", "ZREMRANGEBYSCORE", "ZUNIONSTORE"].to_set
    OTHER_COMMANDS  = ["AUTH", "BGREWRITEAOF", "BGSAVE", "CONFIG GET", "CONFIG SET", "CONFIG RESETSTAT", "DBSIZE", "DEBUG OBJECT", "DEBUG SEGFAULT", "DISCARD", "ECHO", "EXEC", "FLUSHALL", "FLUSHDB", "INFO", "LASTSAVE", "MONITOR", "MULTI", "PING", "PSUBSCRIBE", "PUBLISH", "PUNSUBSCRIBE", "QUIT", "RANDOMKEY", "SAVE", "SELECT", "SHUTDOWN", "SUBSCRIBE", "SYNC", "UNSUBSCRIBE", "UNWATCH", "WATCH"].to_set
    ALL_COMMANDS    = READ_COMMANDS + WRITE_COMMANDS + OTHER_COMMANDS

    NEW_FORMAT        = /^\+?\d+\.\d+ "(.*)"$/i
    OLD_SINGLE_FORMAT = /^(#{NO_ARG_COMMANDS.join('|')})$/i
    OLD_MORE_FORMAT   = /^[A-Z]+ .*$/i

    def self.parse(line)
      new.parse(line)
    end

    def self.reset
      summaries.clear
    end

    def self.pop
      time, summary = self.summaries.first
      if summary.nil?
        summary = summary_hash
      end
      summary["start"] = summary["stop"] = Time.now
      summary["keys"] = Hash[*summary["keys"].sort_by(&:last).reverse[0..99].flatten]
      yield(summary)
      summaries.delete(time) if time
    end

    def self.summaries
      @@summaries ||= {}
    end

    def self.current_summary(time)
      summaries[time] ||= summary_hash
    end

    def self.summary_hash
      {"commands"   => Hash.new(0),
       "keys"       => Hash.new(0),
       "namespaces" => Hash.new(0),
       "totals"     => Hash.new(0)}
    end

    def initialize
      @now = Time.now.utc.strftime("%Y-%m-%d %H:%M:00 %Z")
    end

    def current_summary
      self.class.current_summary(@now)
    end

    def self.start(redis)
      redis.monitor
      redis.on(:monitor) do |line|
        parse(line)
      end
    end

    def parse(line)
      if line =~ NEW_FORMAT
        push($1.split('" "'))
      elsif line =~ OLD_SINGLE_FORMAT || line =~ OLD_MORE_FORMAT
        push(line.split)
      end
    end

    def push(split_command)
      command, key, *rest = split_command
      command.upcase!

      return unless ALL_COMMANDS.member?(command)

      incr_command(command)
      incr_total(command)
      if key
        key.gsub!(".", "{PERIOD}") if key.include?('.')
        key.gsub!("$", "{DOLLAR}") if key.include?('$')

        incr_key(key)
        incr_namespace(key)
      else
        incr_global_namespace
      end
    end

    def incr_namespace(key)
      if marker = key =~ /:|-/
        current_summary["namespaces"][key[0...marker]] += 1
      else
        incr_global_namespace
      end
    end

    def incr_global_namespace
      current_summary["namespaces"]["global"] += 1
    end

    def incr_command(command)
      current_summary["commands"][command] += 1
    end

    def incr_key(key)
      current_summary["keys"][key] += 1
    end

    def incr_total(command)
      current_summary["totals"]["all"] += 1

      if READ_COMMANDS.member?(command)
        current_summary["totals"]["read"] += 1
      elsif WRITE_COMMANDS.member?(command)
        current_summary["totals"]["write"] += 1
      elsif OTHER_COMMANDS.member?(command)
        current_summary["totals"]["other"] += 1
      end
    end
  end
end
