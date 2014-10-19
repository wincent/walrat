# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class Parslet
    include Walrat::ParsletCombining
    include Walrat::Memoizing

    def to_parseable
      self
    end

    def parse string, options = {}
      raise NotImplementedError # subclass responsibility
    end
  end # class Parslet
end # module Walrat
