require 'eventmachine'
require 'alo7/net'
require 'alo7/net/error'

module Alo7
  module Net
    # This is a class that is instantiated by the event loop whenever a new
    # connection is created. New connections can be created by {listen accepting
    # a remote client} or {connect connecting to a remote server}.
    #
    # Users should overwrite {#initialize}, following callbacks included from
    # {Callbacks} to implement their own business logics:
    #
    # * {#post_init}
    # * {#connection_completed}
    # * {#receive_data}
    # * {#unbind}
    #
    # @note This class is considered to be a base class. Use the derived class
    #   {Server} or {Client} instead of this class directly.
    # @note This class should never be instantiated by user code.
    class Connection
      # This method declaires the callbacks users can overwrite to implement
      # their own business logics.
      module Callbacks
        # Called by the event loop immediately after the network connection has
        # been established, and before resumption of the network loop.
        #
        # @return [void]
        #
        # @see #connection_completed
        def post_init
        end

        # Called by the event loop when a remote TCP connection attempt
        # completes successfully.
        #
        # @return [void]
        #
        # @see Net.connect
        # @see #post_init
        def connection_completed
        end

        # Called by the event loop whenever data has been received by the
        # network connection. It's called with a single parameter, a String
        # containing the network protocol data, which may of course be binary.
        # You will generally overwrite this method to perform your own
        # processing of the incoming data.
        #
        # @param data [String] data received from the remote end
        # @return [void]
        #
        # @see #send_data
        def receive_data(data)
        end

        # Called by the event loop whenever a connection (either a server or a
        # client connection) is closed. The close can occur because of your code
        # intentionally (using {#disconnect}), because of the remote end closed
        # the connection, or because of a network error.
        #
        # @return [void]
        #
        # @see #disconnect
        #
        # @note You may not assume that the network connection is still open and
        #   able to send or receive data when the callback to unbind is made.
        #   This is intended only to give you a chance to clean up associations
        #   your code may have made to the connection object while it was open.
        def unbind
        end
      end

      include Callbacks

      # @private
      attr_accessor :impl

      # @param args passed from {listen} or {connect}
      def initialize(*args)
      end

      # Send the data to the remote end of the connection asynchronously.
      #
      # @param data [String] data to send
      # @return [void]
      #
      # @see #receive_data
      #
      # @note Data is buffered to be send which means it is not guaranteed to be
      #   sent immediately when calling this method.
      def send_data(data)
        @impl.send_data data
      end

      # Close the connection asynchronously after all of the outbound data has
      # been written to the remote end. {#unbind} will be called later after
      # this method returns.
      #
      # @return [void]
      #
      # @see #unbind
      def disconnect
        @impl.close_connection_after_writing
      end

      # (see Impl#await)
      def await(defer)
        @impl.await defer
      end

      # @private
      class Impl < EM::Connection
        # @private
        attr_reader :handler

        def initialize(klass, *args)
          raise ArgumentError, "must provide a subclass of #{Connection.name}" \
            unless klass <= Connection
          @handler = klass.new(*args)
          @handler.impl = self
        end

        def post_init
          Net.fiber_block do
            @unbinding = false
            @defers = []

            @handler.post_init
          end
        end

        def connection_completed
          Net.fiber_block { @handler.connection_completed }
        end

        def receive_data(data)
          Net.fiber_block { @handler.receive_data data }
        end

        def unbind
          Net.fiber_block do
            @unbinding = true
            @defers.dup.each { |defer| defer.fail ConnectionLost.new }

            @handler.unbind

            @unbinding = false
          end
        end

        # (see Net.await)
        #
        # @note It keeps the pending defers internally. When unbinding, it fails
        #   them with a ConnectionLost error.
        # @note It fails the defer and raise a ConnectionLost error
        #   intermediately between unbinding.
        def await(defer)
          if @unbinding
            err = ConnectionLost.new
            defer.fail err
            raise err
          else
            _await defer
          end
        end

        private

        def _await(defer)
          @defers.push defer
          begin
            Net.await defer
          ensure
            @defers.delete defer
          end
        end
      end
    end
  end
end
