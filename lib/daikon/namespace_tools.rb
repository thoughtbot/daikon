module Daikon
  module NamespaceTools
    def namespace_input(ns, command, *args)
      command = command.to_s.downcase

      case command

      when "multi", "exec", "discard"

        # No arguments.

        [ command ]

      when "exists", "del", "type", "keys", "ttl", "set", "get", "getset",
           "setnx", "incr", "incrby", "decr", "decrby", "rpush", "lpush",
           "llen", "lrange", "ltrim", "lindex", "lset", "lrem", "lpop", "rpop",
           "sadd", "srem", "spop", "scard", "sismember", "smembers", "srandmember",
           "zadd", "zrem", "zincrby", "zrange", "zrevrange", "zrangebyscore",
           "zcard", "zscore", "zremrangebyscore", "expire", "expireat", "hlen",
           "hkeys", "hvals", "hgetall", "hset", "hget", "hincrby", "hexists",
           "hdel", "hmset"

        # Only the first argument is a key.

        head = add_namespace(ns, args.first)
        tail = args[1, args.length - 1] || []

        [ command, head, *tail ]

      when "smove"

        # The first two parmeters are keys.

        result = [ command ]

        args.each_with_index do |arg, i|
          result << ((i == 0 || i == 1) ? add_namespace(ns, arg) : arg)
        end

        result

      when "mget", "rpoplpush", "sinter", "sunion", "sdiff", "info",
           "sinterstore", "sunionstore", "sdiffstore"

        # All arguments are keys.

        keys = add_namespace(ns, args)

        [ command, *keys ]

      when "mset", "msetnx"

        # Every other argument is a key, starting with the first.

        hash1 = Hash[*args]
        hash2 = {}

        hash1.each do |k, v|
          hash2[add_namespace(ns, k)] = hash1.delete(k)
        end

        [ command, hash2 ]

      when "sort"

        return [] if args.count == 0

        key = add_namespace(ns, args.shift)
        parms = {}

        while keyword = args.shift.andand.downcase
          case keyword
          when "by", "get", "store"
            k = keyword.intern
            v = add_namespace(ns, args.shift)

            parms[k] = v
          when "limit"
            parms[:limit] = [ args.shift.to_i, args.shift.to_i ]
          when "asc", "desc", "alpha"
            parms[:order].andand << " "
            parms[:order] ||= ""
            parms[:order] << keyword
          end
        end

        [ command, key, parms ]

      end
    end

    def denamespace_output(namespace, command, result)
      case command.to_s.downcase

      when "keys"
        remove_namespace namespace, result

      else
        result

      end
    end

    def add_namespace(namespace, key)
      return key unless namespace

      case key
      when String then "#{namespace}:#{key}"
      when Array  then key.map {|k| add_namespace(namespace, k)}
      end
    end

    def remove_namespace(namespace, key)
      return key unless namespace

      case key
      when String then key.gsub(/^#{namespace}:/, "")
      when Array  then key.map {|k| remove_namespace(namespace, k)}
      end
    end
  end
end
