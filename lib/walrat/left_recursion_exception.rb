# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class LeftRecursionException < Exception
    attr_accessor :continuation

    def initialize continuation = nil
      super self.class.to_s
      @continuation = continuation
    end
  end # class LeftRecursionException
end # module Walrat
