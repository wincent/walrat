# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class ContinuationWrapperException < Exception
    attr_reader :continuation

    def initialize continuation
      raise ArgumentError, 'nil continuation' if continuation.nil?
      super self.class.to_s
      @continuation = continuation
    end
  end # class ContinuationWrapperException
end # module Walrat
