require 'alo7/net'
require 'alo7/net/connection'
require 'alo7/net/defer'

module Alo7
  module Net
    # This is a class that provides the client logics.
    class Client < Connection
      # Initiate a TCP connection to a remote server and set up event handling
      # for the connection.
      #
      # @param host [String] host to connect to
      # @param port [Integer] port to connect to
      # @param args passed to the initializer of the client
      # @return [Client] the initiated client instance
      def self.connect(host, port, *args)
        connection = Net.connect self, host, port, *args
        await_connect connection
      end

      # Connect to a given host/port and re-use the instance.
      #
      # @param host [String] host to connect to
      # @param port [Integer] port to connect to
      # @return [self]
      def reconnect(host, port)
        Net.reconnect self, host, port
        self.class.await_connect self
      end

      # @private
      class Impl < Connection::Impl
        attr_accessor :connect_defer

        def connection_completed
          connect_defer, @connect_defer = @connect_defer, nil
          connect_defer.succeed
          super
        end
      end

      class << self
        # @private
        def await_connect(connection)
          defer = Defer.new
          connection.impl.connect_defer = defer
          Net.await defer
          connection
        end
      end
    end
  end
end
