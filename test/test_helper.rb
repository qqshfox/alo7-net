if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'alo7/net'
require 'eventmachine'

require 'minitest/autorun'

module OnPostInit
  def initialize(*args)
    options = args[-1].is_a?(Hash) ? args[-1] : {}
    super
    @on_post_init_proc = options[:on_post_init_proc]
  end

  def post_init
    super
    @on_post_init_proc.call self
  end
end

module OnConnectionCompleted
  def initialize(*args)
    options = args[-1].is_a?(Hash) ? args[-1] : {}
    super
    @on_connection_completed_proc = options[:on_connection_completed_proc]
  end

  def connection_completed
    @on_connection_completed_proc.call self
  end
end

module OnReceiveData
  def initialize(*args)
    options = args[-1].is_a?(Hash) ? args[-1] : {}
    super
    @on_receive_data_proc = options[:on_receive_data_proc]
  end

  def receive_data(data)
    @on_receive_data_proc.call self, data
  end
end

module OnUnbind
  def initialize(*args)
    options = args[-1].is_a?(Hash) ? args[-1] : {}
    super
    @on_unbind_proc = options[:on_unbind_proc]
  end

  def unbind
    @on_unbind_proc.call self
    super
  end
end

def start_server(*args, &block)
  EM.start_server 'localhost', 9999, *args, &block
end

def connect(*args, &block)
  EM.connect 'localhost', 9999, *args, &block
end
