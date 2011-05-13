module Daikon
  class Monitor
    attr_accessor :data

    NO_ARG_COMMANDS = ["BGREWRITEAOF", "BGSAVE", "CONFIG RESETSTAT", "DBSIZE", "DEBUG SEGFAULT", "DISCARD", "EXEC", "FLUSHALL", "FLUSHDB", "INFO", "LASTSAVE", "MONITOR", "MULTI", "PING", "QUIT", "RANDOMKEY", "SAVE", "SHUTDOWN", "SYNC", "UNWATCH"]
    READ_COMMANDS   = ["EXISTS", "GET", "GETBIT", "GETRANGE", "HEXISTS", "HGET", "HGETALL", "HKEYS", "HLEN", "HMGET", "HVALS", "KEYS", "LINDEX", "LLEN", "LRANGE", "MGET", "SCARD", "SDIFF", "SINTER", "SISMEMBER", "SMEMBERS", "SORT", "SRANDMEMBER", "STRLEN", "SUNION", "TTL", "TYPE", "ZCARD", "ZCOUNT", "ZRANGE", "ZRANGEBYSCORE", "ZRANK", "ZREVRANGE", "ZREVRANGEBYSCORE", "ZREVRANK", "ZSCORE"].to_set
    WRITE_COMMANDS  = ["APPEND", "BLPOP", "BRPOP", "BRPOPLPUSH", "DECR", "DECRBY", "DEL", "GETSET", "EXPIRE", "EXPIREAT", "HDEL", "HINCRBY", "HMSET", "HSET", "HSETNX", "INCR", "INCRBY", "LINSERT", "LPOP", "LPUSH", "LPUSHX", "LREM", "LSET", "LTRIM", "MOVE", "MSET", "MSETNX", "PERSIST", "RENAME", "RENAMENX", "RPOP", "RPOPLPUSH", "RPUSH", "RPUSHX", "SADD", "SDIFFSTORE", "SET", "SETBIT", "SETEX", "SETNX", "SETRANGE", "SINTERSTORE", "SMOVE", "SPOP", "SREM", "SUNIONSTORE", "ZADD", "ZINCRBY", "ZINTERSTORE", "ZREM", "ZREMRANGEBYRANK", "ZREMRANGEBYSCORE", "ZUNIONSTORE"].to_set
    OTHER_COMMANDS  = ["AUTH", "BGREWRITEAOF", "BGSAVE", "CONFIG GET", "CONFIG SET", "CONFIG RESETSTAT", "DBSIZE", "DEBUG OBJECT", "DEBUG SEGFAULT", "DISCARD", "ECHO", "EXEC", "FLUSHALL", "FLUSHDB", "INFO", "LASTSAVE", "MONITOR", "MULTI", "PING", "PSUBSCRIBE", "PUBLISH", "PUNSUBSCRIBE", "QUIT", "RANDOMKEY", "SAVE", "SELECT", "SHUTDOWN", "SUBSCRIBE", "SYNC", "UNSUBSCRIBE", "UNWATCH", "WATCH"].to_set
    ALL_COMMANDS    = READ_COMMANDS + WRITE_COMMANDS + OTHER_COMMANDS

    NEW_FORMAT        = /^\+?\d+\.\d+ (?:\(db \d+\) )?"(.*)"$/i
    OLD_SINGLE_FORMAT = /^(#{NO_ARG_COMMANDS.join('|')})$/i
    OLD_MORE_FORMAT   = /^[A-Z]+ .*$/i

    def initialize(redis = nil, logger = nil)
      @data   = data_hash
      @redis  = redis
      @logger = logger
      @mutex  = Mutex.new
    end

    def data_hash
      {"commands"   => Hash.new(0),
       "keys"       => Hash.new(0),
       "namespaces" => Hash.new(0),
       "totals"     => Hash.new(0)}
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
      this_data = nil
      lock do
        this_data = self.data.dup
        self.data.replace(data_hash)
      end
      this_data["keys"] = Hash[*this_data["keys"].sort_by(&:last).reverse[0..99].flatten]
      this_data
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

      lock do
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
    end

    def incr_namespace(key)
      if marker = key =~ /:|-/
        data["namespaces"][key[0...marker]] += 1
      else
        incr_global_namespace
      end
    end

    def incr_global_namespace
      data["namespaces"]["global"] += 1
    end

    def incr_command(command)
      data["commands"][command] += 1
    end

    def incr_key(key)
      data["keys"][key] += 1
    end

    def incr_total(command)
      data["totals"]["all"] += 1

      if READ_COMMANDS.member?(command)
        data["totals"]["read"] += 1
      elsif WRITE_COMMANDS.member?(command)
        data["totals"]["write"] += 1
      elsif OTHER_COMMANDS.member?(command)
        data["totals"]["other"] += 1
      end
    end
  end
end
