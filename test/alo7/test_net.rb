require 'test_helper'

module Alo7
  class TestNet < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil Net::VERSION
    end
  end
end
