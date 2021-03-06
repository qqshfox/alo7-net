require 'test_helper'

module Alo7
  module Net
    class TestClient < Minitest::Test
      def test_that_it_can_connect
        Net.run do
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do
            assert true
            Net.stop
          end)
          connection = Client.connect 'localhost', 9999
          assert_kind_of Client, connection
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      class ReconnectClient < Client
        def initialize(*args)
          @i = 0
        end

        def unbind
          reconnect 'localhost', 9999 if @i == 0
          @i += 1
        end
      end

      def test_that_it_can_reconnect
        Net.run do
          ary = []
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            if ary.size == 1
              assert true
              Net.stop
            else
              assert_equal 0, ary.size
              connection.close_connection
            end
            ary.push ary.size
          end)
          ReconnectClient.connect 'localhost', 9999
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      class ReconnectRaiseClient < Client
        def initialize(*args)
          @i = 0
        end

        def unbind
          if @i == 0
            connection = reconnect 'localhost', 9999
            raise Exception.new 'reconnect returns wrong object' \
              unless connection.object_id == object_id
          end
          @i += 1
        end
      end

      def test_that_it_should_return_the_previous_connection_when_reconnect
        Net.run do
          ary = []
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            if ary.size == 1
              assert true
              Net.stop
            else
              assert_equal 0, ary.size
              connection.close_connection
            end
            ary.push ary.size
          end)
          ReconnectRaiseClient.connect 'localhost', 9999
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      class ExtraArgsClient < Client
        attr_reader :args

        def initialize(*args)
          @args = args
        end
      end

      def test_that_it_can_pass_the_extra_args_when_connect
        Net.run do
          extra_args = [1, true, 'third']

          start_server EM::Connection
          connection = ExtraArgsClient.connect 'localhost', 9999, *extra_args
          assert_equal extra_args, connection.args
          Net.stop
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_should_raise_when_another_reconnecting_is_under_progress
        Net.run do
          first_connection_completed = true
          first_unbind = true
          start_server EM::Connection
          (Class.new(Client) do
            include OnConnectionCompleted
            include OnUnbind
          end).connect('localhost', 9999, on_connection_completed_proc: proc do |connection|
            first, first_connection_completed = first_connection_completed, false
            connection.disconnect if first
          end, on_unbind_proc: proc do |connection|
            first, first_unbind = first_unbind, false
            if first
              Net.fiber_block { connection.reconnect 'localhost', 19999 }
              assert_raises AnotherReconnectingUnderProgress do
                Net.fiber_block { connection.reconnect 'localhost', 19999 }
              end
              Net.stop
            end
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_connection_completed_after_connect
        Net.run do
          start_server EM::Connection
          (Class.new(Client) do
            include OnConnectionCompleted
          end).connect('localhost', 9999, on_connection_completed_proc: proc do
            assert true
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end
    end
  end
end
