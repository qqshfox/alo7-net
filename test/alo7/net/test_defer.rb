require 'test_helper'

module Alo7
  module Net
    class TestDefer < Minitest::Test
      def test_that_it_should_be_kind_of_a_deferrable
        assert_operator Defer, :<, EM::Deferrable
      end
    end
  end
end
