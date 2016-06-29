require 'fiber'
require 'eventmachine'
require 'em-synchrony'
require 'alo7/net/version'
require 'alo7/net/connection'
require 'alo7/net/server'
require 'alo7/net/client'
require 'alo7/net/error'
require 'alo7/net/defer'

module Alo7
  module Net
    # Run an event loop in the fiber way.
    #
    # @overload run(block)
    # @overload run(&block)
    #
    # @param block [MethodObject] the block to run
    # @return [void]
    #
    # @example Starting an event loop in the current thread to run the "Hello, world"-like Echo server example
    #
    #     !!!ruby
    #     require 'alo7-net'
    #
    #     class EchoServer < Alo7::Net::Server
    #       def receive_data(data)
    #         send_data data
    #       end
    #     end
    #
    #     Alo7::Net.run do
    #       EchoServer.listen 3000
    #     end
    #
    # @note This method blocks the calling thread.
    # @note This method only returns if the event loop stopped.
    #
    # @see stop
    def self.run(blk = nil, &block)
      EM.synchrony(blk || block)
    end

    # Run an event loop and then terminate the loop as soon as the block completes.
    #
    # @param block [MethodObject] the block to run once
    # @return [void]
    def self.run_once(&block)
      run do
        block.call
        stop
      end
    end

    # Stop the running event loop.
    #
    # @return [void]
    #
    # @example Stopping a running event loop.
    #
    #     !!!ruby
    #     require 'alo7-net'
    #
    #     class OnceClient < Alo7::Net::Client
    #       def post_init
    #         puts 'sending a dump HTTP request'
    #         send_data "GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n"
    #       end
    #
    #       def receive_data(data)
    #         puts "data.length: #{data.length}"
    #         puts 'stopping the event loop now'
    #         Net.stop
    #       end
    #     end
    #
    #     Alo7::Net.run do
    #       OnceClient.connect 'www.google.com', 80
    #     end
    #
    # @see run
    def self.stop
      EM.stop_event_loop
    end

    # Initiate a TCP server on the specified IP address and port.
    #
    # @overload listen(handler, host, port, *args)
    #   @param handler [ClassObject] a module or class that has an innerclass named `Impl`
    #   @param host [String] host to listen on
    #   @param port [Integer] port to listen on
    #   @param *args passed to the initializer of the handler
    # @overload listen(handler, port, *args)
    #   @param handler [ClassObject] a module or class that has an innerclass named `Impl`
    #   @param port [Integer] port to listen on
    #   @param *args passed to the initializer of the handler
    # @yield [handler] initiated when a connection is made
    # @return [Integer] the internal signature
    #
    # @raise (see check_handler!)
    #
    # @see connect
    def self.listen(handler, host_or_port, port = nil, *args)
      check_handler! handler
      if port
        host = host_or_port
      else
        host = 'localhost'
        port = host_or_port
      end
      EM.start_server host, port, handler::Impl, handler, *args do |server|
        yield server.handler if block_given?
      end
    end

    # Initiate a TCP connection to a remote server and set up event handling for
    # the connection.
    #
    # @param handler [ClassObject] a module or class that has an innerclass named `Impl`
    # @param host [String] host to connect to
    # @param port [Integer] port to connect to
    # @return [handler] the initiated handler instance
    #
    # @raise (see check_handler!)
    #
    # @note This requires event loop to be running. (see {run}).
    #
    # @see listen
    # @see reconnect
    def self.connect(handler, host, port, *args)
      check_handler! handler
      connection = EM.connect host, port, handler::Impl, handler, *args
      connection.handler
    end

    # Connect to a given host/port and re-use the provided handler instance.
    #
    # @param handler [#impl] a instance that has a property named `impl`
    # @param host [String] host to reconnect to
    # @param port [Integer] port to reconnect to
    # @return [handler] the previous handler instance
    #
    # @raise [ArgumentError] if the handler doesn't implement a method named impl
    #
    # @see connect
    # @see listen
    def self.reconnect(handler, host, port)
      raise ArgumentError, 'must provide a impl property' unless handler.respond_to? :impl
      connection = EM.reconnect host, port, handler.impl
      connection.handler
    end

    # Wait the defer succeed and then return anything the defer returns. Or
    # raise the exception from the defer.
    #
    # @param defer [Defer] defer to wait
    # @return anything the defer returns
    #
    # @raise [Exception] the exception returns from defer
    def self.await(defer)
      result = EM::Synchrony.sync defer
      raise result if result.is_a? Exception
      result
    end

    # Execute the block in a fiber.
    #
    # @param args passed as arguments to the block that are executed
    # @yieldparam *args arguments passed from outside
    # @yieldreturn [Object] anything
    # @return [Object] anything returned from the block
    def self.fiber_block(*args)
      Fiber.new { yield(*args) }.resume
    end

    class << self
      private

      # @raise [ArgumentError] if the handler doesn't have a innerclass named Impl
      def check_handler!(handler)
        raise ArgumentError, 'must provide a innerclass of Impl' unless defined? handler::Impl
      end
    end
  end
end
