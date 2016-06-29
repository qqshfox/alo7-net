# alo7-net [![Build Status](https://travis-ci.org/qqshfox/alo7-net.svg)](https://travis-ci.org/qqshfox/alo7-net) [![Coverage Status](https://coveralls.io/repos/github/qqshfox/alo7-net/badge.svg)](https://coveralls.io/github/qqshfox/alo7-net)

alo7-net is the TCP server/client library we developed specifically for our ALO7 Learning Platform. This library provides a way to write asynchronous code in a straight-line fashion using fibers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alo7-net'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alo7-net

## Usage

### Server

```ruby
require 'alo7-net'

class EchoServer < Alo7::Net::Server
  def receive_data(data)
    send_data data
  end
end

Alo7::Net.run do
  EchoServer.listen 3000
end
```

### Client

```ruby
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/qqshfox/alo7-net. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
