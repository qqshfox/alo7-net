#!/usr/bin/env ruby

require 'alo7/net'

class EchoServer < Alo7::Net::Server
  def receive_data(data)
    send_data data
  end
end

Alo7::Net.run do
  EchoServer.listen 3000
end
