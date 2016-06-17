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
    def self.run(blk = nil, &block)
      EM.synchrony(blk || block)
    end

    def self.run_once(&block)
      run do
        block.call
        stop
      end
    end

    def self.stop
      EM.stop_event_loop
    end

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

    def self.connect(handler, host, port, *args)
      check_handler! handler
      connection = EM.connect host, port, handler::Impl, handler, *args
      connection.handler
    end

    def self.reconnect(handler, host, port)
      raise ArgumentError, 'must provide a impl property' unless handler.respond_to? :impl
      connection = EM.reconnect host, port, handler.impl
      connection.handler
    end

    def self.await(defer)
      result = EM::Synchrony.sync defer
      raise result if result.is_a? Exception
      result
    end

    def self.fiber_block(*args)
      Fiber.new { yield(*args) }.resume
    end

    class << self
      private

      def check_handler!(handler)
        raise ArgumentError, 'must provide a innerclass of Impl' unless defined? handler::Impl
      end
    end
  end
end
