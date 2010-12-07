# All of this craziness is necessary since redis-rb doesn't support the
# old way of connecting to MONITOR since it doesn't return the format bytes

class Redis
  def monitor(&block)
    @_redis_version ||= info["redis_version"]

    if @_redis_version < "2"
      @client.call_loop_with_old_protocol(:monitor, &block)
    else
      @client.call_loop(:monitor, &block)
    end
  end

  class Client
    def call_loop_with_old_protocol(*args)
      without_socket_timeout do
        process(args) do
          loop { yield(read_with_old_protocol) }
        end
      end
    end

    def read_with_old_protocol
      begin
        connection.read_with_old_protocol
      rescue Errno::EAGAIN
        disconnect
        raise Errno::EAGAIN, "Timeout reading from the socket"
      rescue Errno::ECONNRESET
        raise Errno::ECONNRESET, "Connection lost"
      end
    end
  end

  class Connection
    def read_with_old_protocol
      reply_type = @sock.gets
      raise Errno::ECONNRESET unless reply_type
      reply_type
    end
  end
end
