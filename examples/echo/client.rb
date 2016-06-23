#!/usr/bin/env ruby

require 'alo7-net'

class EchoClient < Alo7::Net::Client
  def receive_data(data)
    puts data
  end
end

Alo7::Net.run do
  c = EchoClient.connect 'localhost', 3000
  c.send_data 'Hello World!'
end
