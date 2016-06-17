require 'alo7/net'
require 'alo7/net/connection'
require 'alo7/net/defer'

module Alo7
  module Net
    class Client < Connection
      def self.connect(host, port, *args)
        connection = Net.connect self, host, port, *args
        await_connect connection
      end

      def reconnect(host, port)
        Net.reconnect self, host, port
        self.class.await_connect self
      end

      class << self
        def await_connect(connection)
          defer = Defer.new
          connection.define_singleton_method :connection_completed do
            defer.succeed
          end
          Net.await defer
          connection.singleton_class.instance_eval do
            remove_method :connection_completed
          end
          connection
        end
      end
    end
  end
end
