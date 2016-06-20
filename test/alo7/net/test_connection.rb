require 'test_helper'

module Alo7
  module Net
    class TestConnection < Minitest::Test
      def setup
        @rand = Random.new
      end

      def test_that_its_impl_should_be_a_em_connection
        assert_operator Connection::Impl, :<, EM::Connection
      end

      def test_that_it_should_raise_if_incorrect_class_passed
        assert_raises ArgumentError do
          Net.run do
            start_server Connection::Impl, Class
            connect(Module.new do
              include OnUnbind
            end, on_unbind_proc: proc { Net.stop })
          end
        end
      end

      def test_that_it_should_not_raise_if_correct_class_passed
        Net.run do
          start_server Connection::Impl, Connection
          connect(Module.new do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc { Net.stop })
        end
        assert true
      end

      def test_that_it_can_be_use_as_a_server
        Net.run do
          start_server Connection::Impl, Connection
          connect(Module.new do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do
            assert true
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_can_be_use_as_a_client
        Net.run do
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do
            assert true
            Net.stop
          end)
          connect Connection::Impl, Connection
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_post_init_on_connected_as_a_server
        Net.run do
          start_server(Connection::Impl, Class.new(Connection) do
            include OnPostInit
          end, on_post_init_proc: proc do
            assert true
            Net.stop
          end)
          connect EM::Connection
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_post_init_on_connected_as_a_client
        Net.run do
          start_server EM::Connection
          connect(Connection::Impl, Class.new(Connection) do
            include OnPostInit
          end, on_post_init_proc: proc do
            assert true
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_unbind_on_disconnected_as_a_server
        Net.run do
          start_server(Connection::Impl, Class.new(Connection) do
            include OnUnbind
          end, on_unbind_proc: proc do
            assert true
            Net.stop
          end)
          connect(Module.new do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc { |connection| connection.close_connection })
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_unbind_on_disconnected_as_a_client
        Net.run do
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc { |connection| connection.close_connection })
          connect(Connection::Impl, Class.new(Connection) do
            include OnUnbind
          end, on_unbind_proc:  proc do
            assert true
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_receive_data_with_the_arrival_data_on_new_data_incoming_as_a_server
        Net.run do
          test_data = 'test message'
          start_server(Connection::Impl, Class.new(Connection) do
            include OnReceiveData
          end, on_receive_data_proc: proc do |_connection, data|
            assert_equal test_data, data
            Net.stop
          end)
          connect(Module.new do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc { |connection| connection.send_data test_data })
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_receive_data_with_the_arrival_data_on_new_data_incoming_as_a_client
        Net.run do
          test_data = 'test message'
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc { |connection| connection.send_data test_data })
          connect(Connection::Impl, Class.new(Connection) do
            include OnReceiveData
          end, on_receive_data_proc: proc do |_connection, data|
            assert_equal test_data, data
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_receive_data_multiple_times_with_enough_data_on_large_data_incoming_as_a_server
        Net.run do
          large_data = @rand.bytes(50000)
          times = 0
          buf = ''

          start_server(Connection::Impl, Class.new(Connection) do
            include OnReceiveData
            include OnUnbind
          end, on_receive_data_proc: proc do |_connection, data|
            times += 1
            buf.concat data
          end, on_unbind_proc: proc do
            assert_operator times, :>, 1
            assert_equal large_data, buf
            Net.stop
          end)
          connect(Module.new do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do |connection|
            connection.send_data large_data
            connection.close_connection_after_writing
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_receive_data_multiple_times_with_enough_data_on_large_data_incoming_as_a_client
        Net.run do
          large_data = @rand.bytes 50000
          buf = ''
          times = 0

          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            connection.send_data large_data
            connection.close_connection_after_writing
          end)
          connect(Connection::Impl, Class.new(Connection) do
            include OnReceiveData
            include OnUnbind
          end, on_receive_data_proc: proc do |_connection, data|
            times += 1
            buf.concat(data)
          end, on_unbind_proc: proc do
            assert_operator times, :>, 1
            assert_equal large_data, buf
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_connection_completed_on_connected_as_a_client
        Net.run do
          start_server EM::Connection
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do
            assert true
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_call_connection_completed_after_post_init_on_connected_as_a_client
        Net.run do
          start_server EM::Connection
          i = 0
          connect(Connection::Impl, Class.new(Connection) do
            include OnPostInit
            include OnConnectionCompleted
          end, on_post_init_proc: proc do
            assert_equal 0, i
            i += 1
          end, on_connection_completed_proc: proc do
            assert_equal 1, i
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_raise_when_yield_in_connection_completed_of_impl
        Net.run do
          start_server EM::Connection
          connect(Class.new(Connection::Impl) do
            include OnConnectionCompleted
          end, Connection, on_connection_completed_proc: proc do
            assert_raises(FiberError) do
              Fiber.yield
            end
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_can_send_data
        Net.run do
          test_message = 'test message'
          start_server(Module.new do
            include OnReceiveData
          end, on_receive_data_proc: proc do |_connection, data|
            assert_equal test_message, data
            Net.stop
          end)
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do |connection|
            connection.send_data test_message
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_can_disconnect
        Net.run do
          start_server(Module.new do
            include OnUnbind
          end, on_unbind_proc: proc do
            assert true
            Net.stop
          end)
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do |connection|
            connection.disconnect
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_block_after_send_data_until_receive_data
        Net.run do
          test_data = 'test message'
          start_server(Module.new do
            include OnReceiveData
          end, on_receive_data_proc: proc do |connection, data|
            connection.send_data data
          end)
          defer = Defer.new
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
            include OnReceiveData
          end, on_connection_completed_proc: proc do |connection|
            connection.send_data test_data
            recv_data = connection.await defer
            assert_equal test_data, recv_data
            Net.stop
          end, on_receive_data_proc: proc do |_connection, data|
            defer.succeed data
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_raise_when_unbind_with_defer_not_finished
        Net.run do
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            connection.send_data 'test'
            connection.close_connection_after_writing
          end)
          defer = Defer.new
          connect(Connection::Impl, Class.new(Connection) do
            include OnReceiveData
          end, on_receive_data_proc: proc do |connection|
            assert_raises(ConnectionLost) do
              connection.await defer
            end
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_raise_when_unbinding_but_still_await
        Net.run do
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            connection.close_connection_after_writing
          end)
          defer = Defer.new
          connect(Connection::Impl, Class.new(Connection) do
            include OnUnbind
          end, on_unbind_proc: proc do |connection|
            assert_raises(ConnectionLost) do
              connection.await defer
            end
            Net.stop
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_can_have_more_than_one_running_defer_at_the_same_time
        Net.run do
          test_data = '01'
          start_server(Module.new do
            include OnPostInit
          end, on_post_init_proc: proc do |connection|
            connection.send_data test_data
          end)
          defers = [Defer.new, Defer.new]
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
            include OnReceiveData
          end, on_connection_completed_proc: proc do |connection|
            Net.fiber_block do
              recv_data = connection.await defers[0]
              assert_equal test_data[0], recv_data
            end

            Net.fiber_block do
              recv_data = connection.await defers[1]
              assert_equal test_data[1], recv_data

              Net.stop
            end
          end, on_receive_data_proc: proc do |_connection, data|
            assert_equal test_data, data
            defers[0].succeed data[0]
            defers[1].succeed data[1]
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_raise_when_unbinding_but_still_multiple_await
        Net.run do
          start_server(EM::Connection)
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do |connection|
            i = 0

            Net.fiber_block do
              assert_raises(ConnectionLost) { connection.await Defer.new }

              Net.stop if i == 1
              i += 1
            end

            Net.fiber_block do
              assert_raises(ConnectionLost) { connection.await Defer.new }

              Net.stop if i == 1
              i += 1
            end

            connection.disconnect
          end)
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      def test_that_it_should_keep_order_when_unbinding_but_still_multiple_await
        Net.run do
          start_server(EM::Connection)
          connect(Connection::Impl, Class.new(Connection) do
            include OnConnectionCompleted
          end, on_connection_completed_proc: proc do |connection|
            total = 10
            result = {}
            total.times do |i|
              Net.fiber_block do
                if i != total - 1
                  assert_raises(ConnectionLost) { connection.await Defer.new }
                  assert_nil result[i]
                  result[i] = true
                else
                  Net.stop
                end
              end
            end
            connection.disconnect
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
