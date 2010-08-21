# Copyright 2007-2010 Wincent Colaiuta. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
