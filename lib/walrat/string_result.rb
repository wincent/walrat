# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class StringResult < String
    include LocationTracking

    def initialize string = ""
      self.source_text = string
      super
    end
  end # class StringResult
end # module Walrat
