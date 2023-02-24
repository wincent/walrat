# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  # ParsletRepetitionDefault is a subclass that modifies the behaviour of its
  # parent, ParsletRepetition, in a very small way. Namely, if the outcome of
  # parsing is a ZeroWidthParse success then it is caught and the default value
  # (defined at initialization time) is returned instead.
  class ParsletRepetitionDefault < ParsletRepetition
    # Possible re-factoring to consider for the future: roll the functionality
    # of this class in to ParsletRepetition itself.
    # Benefit of keeping it separate is that the ParsletRepetition itself is
    # kept simple.
    def initialize parseable, min, max = nil, default = nil
      super parseable, min, max
      self.default  = default
    end

    def parse string, options = {}
      catch :ZeroWidthParseSuccess do
        return super string, options
      end
      @default.clone rescue @default
    end

    def eql?(other)
      other.instance_of? ParsletRepetitionDefault and
        @min == other.min and
        @max == other.max and
        @parseable.eql? other.parseable and
        @default == other.default
    end

  protected

    # For determining equality.
    attr_reader :default

  private

    def hash_offset
      69
    end

    def update_hash
      # let super calculate its share of the hash first
      @hash = super + @default.hash
    end

    def default=(default)
      @default = (default.clone rescue default)
      @default.extend LocationTracking
      update_hash
    end
  end # class ParsletRepetitionDefault
end # module Walrat
