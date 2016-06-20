require 'test_helper'

module Alo7
  module Net
    class TestError < Minitest::Test
      def test_that_error_should_be_kind_of_a_standard_error
        assert_operator Error, :<, StandardError
      end

      def test_that_connection_lost_should_be_kind_of_an_error
        assert_operator ConnectionLost, :<, Error
      end
    end
  end
end
