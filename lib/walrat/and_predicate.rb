# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class AndPredicate < Predicate
    def parse string, options = {}
      raise ArgumentError if string.nil?
      catch :ZeroWidthParseSuccess do
        begin
          parsed = @parseable.memoizing_parse string, options
        rescue ParseError
          raise ParseError.new('predicate not satisfied (expected "%s") while parsing "%s"' % [@parseable.to_s, string],
                               :line_end => options[:line_start],
                               :column_end => options[:column_start])
        end
      end

      # getting this far means that parsing succeeded
      throw :AndPredicateSuccess
    end

  private

    def hash_offset
      12
    end
  end
end # module Walrat
