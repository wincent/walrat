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
  class ParsletOmission < ParsletCombination
    attr_reader :hash

    # Raises an ArgumentError if parseable is nil.
    def initialize parseable
      raise ArgumentError, 'nil parseable' if parseable.nil?
      @parseable = parseable

      # fixed offset to avoid unwanted collisions with similar classes
      @hash = @parseable.hash + 46
    end

    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      substring = StringResult.new
      substring.start = [options[:line_start], options[:column_start]]
      substring.end   = [options[:line_start], options[:column_start]]

      # possibly should catch these here as well
      #catch :NotPredicateSuccess do
      #catch :AndPredicateSuccess do
      # one of the fundamental problems is that if a parslet throws such a
      # symbol any info about already skipped material is lost (because the
      # symbols contain nothing)
      # this may be one reason to change these to exceptions...
      catch :ZeroWidthParseSuccess do
        substring = @parseable.memoizing_parse(string, options)
      end

      # not enough to just return a ZeroWidthParseSuccess here; that could
      # cause higher levels to stop parsing and in any case there'd be no
      # clean way to embed the scanned substring in the symbol
      raise SkippedSubstringException.new(substring,
                                          :line_start   => options[:line_start],
                                          :column_start => options[:column_start],
                                          :line_end     => substring.line_end,
                                          :column_end   => substring.column_end)
    end

    def eql?(other)
      other.instance_of? ParsletOmission and other.parseable.eql? @parseable
    end

  protected

    # For determining equality.
    attr_reader :parseable
  end # class ParsletOmission
end # module Walrat
