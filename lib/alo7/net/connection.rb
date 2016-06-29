require 'eventmachine'
require 'alo7/net'
require 'alo7/net/error'

module Alo7
  module Net
    class Connection
      module Callbacks
        def post_init
        end

        def connection_completed
        end

        def receive_data(data)
        end

        def unbind
        end
      end

      include Callbacks

      attr_accessor :impl

      def initialize(*args)
      end

      def send_data(data)
        @impl.send_data data
      end

      def disconnect
        @impl.close_connection_after_writing
      end

      def await(defer)
        @impl.await defer
      end

      class Impl < EM::Connection
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
