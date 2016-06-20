require 'test_helper'

module Alo7
  class TestNet < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil Net::VERSION
    end

    def test_that_it_will_run_only_once_and_stop
      i = 0
      timer = nil
      Net.run_once do
        timer = EM.add_timer(1) { assert false }
        i += 1
      end
      EM.cancel_timer timer
      assert_equal 1, i
    end

    def test_that_it_will_start_a_event_loop_using_block
      Net.run do
        assert true
        EM.stop_event_loop
      end
    end

    def test_that_it_will_start_a_event_loop_using_a_param
      Net.run(proc do
        assert true
        EM.stop_event_loop
      end)
    end

    def test_that_it_will_start_a_event_loop_using_a_param_when_both_param_and_block_provided
      result = []
      Net.run(proc do
        result.push 1
        EM.stop_event_loop
      end) do
        result.push 2
        assert false
        EM.stop_event_loop
      end
      assert_equal [1], result
    end

    def test_that_it_will_stop
      Net.run do
        Net.stop
      end
      assert true
    end

    def test_that_it_should_raise_listen_on_an_incorrect_handler_when_listen
      assert_raises(ArgumentError) { Net.listen Class, 'localhost', 9999 }
    end

    class Connection
      module Impl
        attr_accessor :handler

        def initialize(klass)
          @handler = klass.new
        end
      end
    end

    def test_that_it_can_listen
      Net.run do
        Net.listen Connection, 'localhost', 9999
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

    def test_that_it_can_listen_when_no_host
      Net.run do
        Net.listen Connection, 9999
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

    def test_that_it_should_yield_the_server_instance_when_connection_made
      Net.run do
        Net.listen Connection, 'localhost', 9999 do |server|
          assert_kind_of Connection, server
          Net.stop
        end
        connect Module.new
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    class ExtraArgsConnection
      attr_reader :args

      def initialize(*args)
        @args = args
      end

      class Impl < EM::Connection
        attr_reader :handler

        def initialize(klass, *args)
          @handler = klass.new(*args)
        end
      end
    end

    def test_that_it_can_pass_the_extra_args_when_listen
      Net.run do
        extra_args = [1, true, 'third']

        Net.listen ExtraArgsConnection, 'localhost', 9999, *extra_args do |server|
          assert_equal extra_args, server.args
          Net.stop
        end
        connect EM::Connection
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    def test_that_it_should_raise_listen_on_an_incorrect_handler_when_connect
      assert_raises(ArgumentError) { Net.connect Class, 'localhost', 9999 }
    end

    def test_that_it_can_connect
      Net.run do
        start_server(Module.new do
          include OnPostInit
        end, on_post_init_proc: proc do
          assert true
          Net.stop
        end)
        connection = Net.connect Connection, 'localhost', 9999
        assert_kind_of Connection, connection
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    def test_that_it_can_pass_the_extra_args_when_connect
      Net.run do
        extra_args = [1, true, 'third']

        start_server EM::Connection
        connection = Net.connect ExtraArgsConnection, 'localhost', 9999, *extra_args
        assert_equal extra_args, connection.args
        Net.stop
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    def test_that_it_should_raise_listen_on_an_incorrect_handler_when_reconnect
      assert_raises(ArgumentError) { Net.reconnect Class.new, 'localhost', 9999 }
    end

    class ReconnectClient
      attr_accessor :impl

      class Impl < EM::Connection
        attr_accessor :handler

        def initialize(klass)
          @handler = klass.new
          @handler.impl = self
          @i = 0
        end

        def unbind
          Net.reconnect @handler, 'localhost', 9999 if @i == 0
          @i += 1
        end
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
        Net.connect ReconnectClient, 'localhost', 9999
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    class ReconnectRaiseClient
      attr_accessor :impl

      class Impl < EM::Connection
        attr_accessor :handler

        def initialize(klass)
          @handler = klass.new
          @handler.impl = self
          @i = 0
        end

        def unbind
          if @i == 0
            connection = Net.reconnect @handler, 'localhost', 9999
            raise Exception.new 'reconnect returns wrong object' \
              unless connection.object_id == @handler.object_id
          end
          @i += 1
        end
      end
    end

    def test_that_it_reconnect_returns_the_previous_handler
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
        Net.connect ReconnectRaiseClient, 'localhost', 9999
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end

    def test_that_await_should_work
      Net.run_once do
        defer = EM::DefaultDeferrable.new
        EM.add_timer(0) { defer.succeed }
        timer = EM.add_timer(1) { assert false }
        Net.await defer
        EM.cancel_timer timer
        assert true
      end
    end

    def test_that_await_should_raise_exception_when_error
      Net.run_once do
        defer = EM::DefaultDeferrable.new
        EM.add_timer(0) { defer.fail Exception.new }
        timer = EM.add_timer(1) { assert false }
        assert_raises(Exception) { Net.await defer }
        EM.cancel_timer timer
        assert true
      end
    end

    def test_that_it_should_spawn_a_new_fiber
      Net.run_once do
        f = Fiber.current
        Net.fiber_block { refute_equal f, Fiber.current }
      end
    end

    def test_that_it_should_pass_all_args_to_the_spawned_fiber
      Net.run_once do
        args = [1, true, {a: "test"}, [1, 2, 3]]
        Net.fiber_block(*args) { |*params| assert_equal args, params }
      end
    end

    def test_that_it_can_be_inherited_and_be_used_as_a_server
      Net.run do
        Net.listen Class.new(Connection), 9999
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

    def test_that_it_can_be_inherited_and_be_used_as_a_client
      Net.run do
        start_server(Module.new do
          include OnPostInit
        end, on_post_init_proc: proc do
          assert true
          Net.stop
        end)
        klass = Class.new(Connection)
        connection = Net.connect klass, 'localhost', 9999
        assert_kind_of klass, connection
        EM.add_timer 1 do
          assert false
          Net.stop
        end
      end
    end
  end
end
