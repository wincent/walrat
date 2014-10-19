# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class NotPredicate < Predicate
    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      catch :ZeroWidthParseSuccess do
        begin
          @parseable.memoizing_parse(string, options)
        rescue ParseError # failed to pass (which is just what we wanted)
          throw :NotPredicateSuccess
        end
      end

      # getting this far means that parsing succeeded (not what we wanted)
      raise ParseError.new('predicate not satisfied ("%s" not allowed) while parsing "%s"' % [@parseable.to_s, string],
                           :line_end => options[:line_start],
                           :column_end => options[:column_start])
    end

  private

    def hash_offset
      11
    end
  end
end # module Walrat
