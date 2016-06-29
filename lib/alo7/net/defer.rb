require 'em/deferrable'

module Alo7
  module Net
    # This is a callback which will be put off until later.
    class Defer
      include EM::Deferrable

      # @!method callback(&block)
      #   Specify a block to be executed if and when the Deferrable object succeeded.
      #
      #   * If there is no status, add a callback to an internal list.
      #   * If status is succeeded, execute the callback immediately.
      #   * If status is failed, do nothing.
      #
      #   @param block [MethodObject]
      #   @return [self]

      # @!method cancel_callback
      #   Cancels an outstanding callback to &block if any. Undoes the action of {#callback}.
      #
      #   @return [MethodObject] The cancelled callback.

      # @!method errback
      #   Specify a block to be executed if and when the Deferrable object failed.
      #
      #   * If there is no status, add a errback to an internal list.
      #   * If status is failed, execute the errback immediately.
      #   * If status is succeeded, do nothing.
      #
      #   @param block [MethodObject]
      #   @return [self]

      # @!method cancel_errback
      #   Cancels an outstanding errback to &block if any. Undoes the action of {#errback}.
      #
      #   @return [MethodObject] The cancelled errback.

      # @!method succeed(*args)
      #   Execute all of the blocks passed to the object using the {#callback}
      #   method (if any) BEFORE this method returns. All of the blocks passed
      #   to the object using {#errback} will be discarded.
      #
      #   @param args passed as arguments to any callbacks that are executed
      #   @return [void]

      # @!method fail(*args)
      #   Execute all of the blocks passed to the object using the {#errback}
      #   method (if any) BEFORE this method returns. All of the blocks passed
      #   to the object using {#callback} will be discarded.
      #
      #   @param args passed as arguments to any errbacks that are executed
      #   @return [void]
    end
  end
end
