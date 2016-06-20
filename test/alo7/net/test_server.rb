require 'test_helper'

module Alo7
  module Net
    class TestServer < Minitest::Test
      def test_that_it_can_listen
        Net.run do
          Server.listen 'localhost', 9999
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
          Server.listen 9999
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
          Server.listen 'localhost', 9999 do |server|
            assert_kind_of Server, server
            Net.stop
          end
          connect Module.new
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end

      class ExtraArgsServer < Server
        attr_reader :args

        def initialize(*args)
          @args = args
        end
      end

      def test_that_it_can_pass_the_extra_args_when_listen
        Net.run do
          extra_args = [1, true, 'third']

          ExtraArgsServer.listen 'localhost', 9999, *extra_args do |connection|
            assert_equal extra_args, connection.args
            Net.stop
          end
          connect Module.new
          EM.add_timer 1 do
            assert false
            Net.stop
          end
        end
      end
    end
  end
end
