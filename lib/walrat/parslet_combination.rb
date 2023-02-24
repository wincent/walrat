# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class ParsletCombination
    include Walrat::ParsletCombining
    include Walrat::Memoizing

    def to_parseable
      self
    end
  end # module ParsletCombination
end # module Walrat
