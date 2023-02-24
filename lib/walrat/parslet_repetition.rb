# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class ParsletRepetition < ParsletCombination
    attr_reader :hash

    # Raises an ArgumentError if parseable or min is nil.
    def initialize parseable, min, max = nil
      raise ArgumentError, 'nil parseable' if parseable.nil?
      raise ArgumentError, 'nil min' if min.nil?
      @parseable = parseable
      self.min = min
      self.max = max
    end

    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      state = ParserState.new string, options
      catch :ZeroWidthParseSuccess do             # a zero-width match is grounds for immediate abort
        while @max.nil? or state.length < @max    # try forever if max is nil; otherwise keep trying while match count < max
          begin
            parsed = @parseable.memoizing_parse state.remainder, state.options
            state.parsed parsed
          rescue SkippedSubstringException => e
            state.skipped e
          rescue ParseError => e # failed, will try to skip; save original error in case skipping fails
            if options.has_key?(:skipping_override)
              skipping_parslet = options[:skipping_override]
            elsif options.has_key?(:skipping)
              skipping_parslet = options[:skipping]
            else
              skipping_parslet = nil
            end
            break if skipping_parslet.nil?
            begin
              # guard against self references (possible infinite recursion) here?
              parsed = skipping_parslet.memoizing_parse state.remainder, state.options
              state.skipped parsed
              redo  # skipping succeeded, try to redo
            rescue ParseError
              break # skipping didn't help either, give up
            end
          end
        end
      end

      # now assess whether our tries met the requirements
      if state.length == 0 and @min == 0 # success (special case)
        throw :ZeroWidthParseSuccess
      elsif state.length < @min          # matches < min (failure)
        raise ParseError.new('required %d matches but obtained %d while parsing "%s"' % [@min, state.length, string],
                             :line_end    => state.options[:line_end],
                             :column_end  => state.options[:column_end])
      else                              # success (general case)
        state.results                   # returns multiple matches as an array, single matches as a single object
      end
    end

    def eql?(other)
      other.instance_of? ParsletRepetition and
        @min == other.min and
        @max == other.max and
        @parseable.eql? other.parseable
    end

  protected

    # For determining equality.
    attr_reader :parseable, :min, :max

  private

    def hash_offset
      87
    end

    def update_hash
      # fixed offset to minimize risk of collisions
      @hash = @min.hash + @max.hash + @parseable.hash + hash_offset
    end

    def min=(min)
      @min = (min.clone rescue min)
      update_hash
    end

    def max=(max)
      @max = (max.clone rescue max)
      update_hash
    end
  end # class ParsletRepetition
end # module Walrat
