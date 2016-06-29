require 'alo7/net'
require 'alo7/net/connection'

module Alo7
  module Net
    # This is a class that provides the server logics.
    class Server < Connection
      # Initiate a TCP server on the specified IP address and port.
      #
      # @overload listen(host, port)
      #   @param host [String] host to listen on
      #   @param port [Integer] port to listen on
      #   @param *args passed to the initializer of the server
      # @overload listen(port)
      #   @param port [Integer] port to listen on
      #   @param *args passed to the initializer of the server
      # @yield [connection] initiated when a connection is made
      # @return (see Net.listen)
      #
      # @raise (see Net.listen)
      def self.listen(host_or_port, port = nil, *args, &block)
        Net.listen self, host_or_port, port, *args, &block
      end
    end
  end
end
