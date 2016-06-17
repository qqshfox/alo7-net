require 'alo7/net'
require 'alo7/net/connection'

module Alo7
  module Net
    class Server < Connection
      def self.listen(host_or_port, port = nil, *args, &block)
        Net.listen self, host_or_port, port, *args, &block
      end
    end
  end
end
