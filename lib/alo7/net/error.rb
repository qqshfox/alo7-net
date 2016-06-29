module Alo7
  module Net
    # The base error type in this library. All other errors should derived from
    # this class.
    class Error < StandardError; end

    # A error used to indicate a connection lost.
    class ConnectionLost < Error; end
  end
end
