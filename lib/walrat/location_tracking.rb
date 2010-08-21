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
  # Methods for embedding location information in objects returned (or
  # exceptions raised) from parse methods.
  module LocationTracking
    attr_reader :source_text

    # For occasions where a single item must serve as a carrier for array-like
    # information (that is, its own start, end and source_text, as well as the
    # "outer" equivalents). This can happen where a single node appears in a
    # list context surrounded only by skipped content.
    attr_accessor :outer_start, :outer_end, :outer_source_text

    def source_text=(string)
      @source_text = string.to_s.clone
    end

    # Sets @column_start to col.
    # Sets @column_start to 0 if passed nil (for ease of use, users of classes
    # that mix-in this module don't have to worry about special casing nil
    # values).
    def column_start=(column_start)
      @column_start = column_start.to_i
    end

    # Returns 0 if @column_start is nil (for ease of use, users of classes that
    # mix-in this module don't have to worry about special casing nil values).
    def column_start
      @column_start || 0
    end

    # Sets @line_start to line.
    # Sets @line_start to 0 if passed nil (for ease of use, users of classes
    # that mix-in this module don't have to worry about special casing nil
    # values).
    def line_start=(line_start)
      @line_start = line_start.to_i
    end

    # Returns 0 if @line_start is nil (for ease of use, users of classes that
    # mix-in this module don't have to worry about special casing nil values).
    def line_start
      @line_start || 0
    end

    # Convenience method for getting both line_start and column_start at once.
    def start
      [self.line_start, self.column_start]
    end

    # Convenience method for setting both line_start and column_start at once.
    def start=(array)
      raise ArgumentError if array.nil?
      raise ArgumentError if array.length != 2
      self.line_start    = array[0]
      self.column_start  = array[1]
    end

    def line_end=(line_end)
      @line_end = line_end.to_i
    end

    def line_end
      @line_end || 0
    end

    def column_end=(column_end)
      @column_end = column_end.to_i
    end

    def column_end
      @column_end || 0
    end

    # Convenience method for getting both line_end and column_end at once.
    def end
      [self.line_end, self.column_end]
    end

    # Convenience method for setting both line_end and column_end at once.
    def end=(array)
      raise ArgumentError if array.nil?
      raise ArgumentError if array.length != 2
      self.line_end   = array[0]
      self.column_end = array[1]
    end

    # Given another object that responds to column_end and line_end, returns
    # true if the receiver is rightmost or equal.
    # If the other object is farther to the right returns false.
    def rightmost? other
      if self.line_end > other.line_end
        true
      elsif other.line_end > self.line_end
        false
      elsif self.column_end >= other.column_end
        true
      else
        false
      end
    end
  end # module LocationTracking
end # module Walrat
