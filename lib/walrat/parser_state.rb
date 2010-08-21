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
  # Simple class for maintaining state during a parse operation.
  class ParserState
    attr_reader :options

    # Returns the remainder (the unparsed portion) of the string. Will return
    # an empty string if already at the end of the string.
    attr_reader :remainder

    # Raises an ArgumentError if string is nil.
    def initialize string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      self.base_string        = string
      @results                = ArrayResult.new # for accumulating results
      @remainder              = @base_string.clone
      @scanned                = ''
      @options                = options.clone

      # start wherever we last finished (doesn't seem to behave different to
      # the alternative)
      @options[:line_start]   = (@options[:line_end] or @options[:line_start] or 0)
      @options[:column_start] = (@options[:column_end] or @options[:column_start] or 0)
      #@options[:line_start]   = 0 if @options[:line_start].nil?
      #@options[:column_start] = 0 if @options[:column_start].nil?

      # before parsing begins, end point is equal to start point
      @options[:line_end]     = @options[:line_start]
      @options[:column_end]   = @options[:column_start]
      @original_line_start    = @options[:line_start]
      @original_column_start  = @options[:column_start]
    end

    # The parsed method is used to inform the receiver of a successful parsing
    # event.
    #
    # Note that substring need not actually be a String but it must respond to
    # the following messages:
    #   - "line_end" and "column_end" so that the end position of the receiver
    #     can be updated
    # As a convenience returns the remainder.
    # Raises an ArgumentError if substring is nil.
    def parsed substring
      raise ArgumentError if substring.nil?
      update_and_return_remainder_for_string substring, true
    end

    # The skipped method is used to inform the receiver of a successful parsing
    # event where the parsed substring should be consumed but not included in
    # the accumulated results.
    # The substring should respond to "line_end" and "column_end".
    # In all other respects this method behaves exactly like the parsed method.
    def skipped substring
      raise ArgumentError if substring.nil?
      update_and_return_remainder_for_string substring
    end

    # The auto_skipped method is used to inform the receiver of a successful
    # parsing event where the parsed substring should be consumed but not
    # included in the accumulated results and furthermore the parse event
    # should not affect the overall bounds of the parse result. In reality this
    # means that the method is only ever called upon the successful use of a
    # automatic intertoken "skipping" parslet. By definition this method should
    # only be called for intertoken skipping otherwise incorrect results will
    # be produced.
    def auto_skipped substring
      raise ArgumentError if substring.nil?
      a, b, c, d = @options[:line_start], @options[:column_start],
        @options[:line_end], @options[:column_end] # save
      remainder = update_and_return_remainder_for_string(substring)
      @options[:line_start], @options[:column_start],
        @options[:line_end], @options[:column_end] = a, b, c, d # restore
      remainder
    end

    # Returns the results accumulated so far.
    # Returns an empty array if no results have been accumulated.
    # Returns a single object if only one result has been accumulated.
    # Returns an array of objects if multiple results have been accumulated.
    def results
      updated_start       = [@original_line_start, @original_column_start]
      updated_end         = [@options[:line_end], @options[:column_end]]
      updated_source_text = @scanned.clone

      if @results.length == 1
        # here we ask the single result to exhibit container-like properties
        # use the "outer" variants so as to not overwrite any data internal to
        # the result itself
        # this can happen where a lone result is surrounded only by skipped
        # elements
        # the result has to convey data about its own limits, plus those of the
        # context just around it
        results = @results[0]
        results.outer_start       = updated_start if results.start != updated_start
        results.outer_end         = updated_end if results.end != updated_end
        results.outer_source_text = updated_source_text if results.source_text != updated_source_text

        # the above trick fixes some of the location tracking issues but opens
        # up another can of worms
        # uncomment this line to see
        #return results

        # need some way of handling unwrapped results (raw results, not AST
        # nodes) as well
        results.start             = updated_start
        results.end               = updated_end
        results.source_text       = updated_source_text
      else
        results = @results
        results.start             = updated_start
        results.end               = updated_end
        results.source_text       = updated_source_text
      end
      results
    end

    # Returns the number of results accumulated so far.
    def length
      @results.length
    end

    # TODO: possibly implement "undo/rollback" and "reset" methods
    # if I implement "undo" will probbaly do it as a stack
    # will have the option of implementing "redo" as well but I'd only do that if I could think of a use for it

  private

    def update_and_return_remainder_for_string input, store = false
      previous_line_end   = @options[:line_end]   # remember old end point
      previous_column_end = @options[:column_end] # remember old end point

      # special case handling for literal String objects
      if input.instance_of? String
        input = StringResult.new(input)
        input.start = [previous_line_end, previous_column_end]
        if (line_count  = input.scan(/\r\n|\r|\n/).length) != 0       # count number of newlines in receiver
          column_end    = input.jlength - input.jrindex(/\r|\n/) - 1  # calculate characters on last line
        else                                                          # no newlines in match
          column_end    = input.jlength + previous_column_end
        end
        input.end   = [previous_line_end + line_count, column_end]
      end

      @results << input if store

      if input.line_end > previous_line_end       # end line has advanced
        @options[:line_end]   = input.line_end
        @options[:column_end] = 0
      end

      if input.column_end > @options[:column_end] # end column has advanced
        @options[:column_end] = input.column_end
      end

      @options[:line_start]   = @options[:line_end]   # new start point is old end point
      @options[:column_start] = @options[:column_end] # new start point is old end point

      # calculate remainder
      line_delta              = @options[:line_end] - previous_line_end
      if line_delta > 0                                                     # have consumed newline(s)
        line_delta.times do                                                 # remove them from remainder
          newline_location    = @remainder.jindex_plus_length /\r\n|\r|\n/  # find the location of the next newline
          @scanned            << @remainder[0...newline_location]           # record scanned text
          @remainder          = @remainder[newline_location..-1]            # strip everything up to and including the newline
        end
        @scanned              << @remainder[0...@options[:column_end]]
        @remainder            = @remainder[@options[:column_end]..-1] # delete up to the current column
      else                                                            # no newlines consumed
        column_delta          = @options[:column_end] - previous_column_end
        if column_delta > 0                                           # there was movement within currentline
          @scanned            << @remainder[0...column_delta]
          @remainder          = @remainder[column_delta..-1]          # delete up to the current column
        end
      end
      @remainder
    end

    def base_string=(string)
      @base_string = (string.clone rescue string)
    end
  end # class ParserState
end # module Walrat
