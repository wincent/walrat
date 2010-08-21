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
  class ParsletChoice < ParsletCombination
    attr_reader :hash

    # Either parameter may be a Parslet or a ParsletCombination.
    # Neither parmeter may be nil.
    def initialize left, right, *others
      raise ArgumentError if left.nil?
      raise ArgumentError if right.nil?
      @alternatives = [left, right] + others
      update_hash
    end

    # Override so that alternatives are appended to an existing sequence:
    # Consider the following example:
    #
    #     A | B
    #
    # This constitutes a single choice:
    #
    #     (A | B)
    #
    # If we then make this a three-element sequence:
    #
    #     A | B | C
    #
    # We are effectively creating an nested sequence containing the original
    # sequence and an additional element:
    #
    #     ((A | B) | C)
    #
    # Although such a nested sequence is correctly parsed it is not as
    # architecturally clean as a single sequence without nesting:
    #
    #     (A | B | C)
    #
    # This method allows us to use the architecturally cleaner format.
    def |(next_parslet)
      append next_parslet
    end

    # First tries to parse the left option, falling back and trying the right
    # option and then the any subsequent options in the others instance
    # variable on failure. If no options successfully complete parsing then an
    # ParseError is raised. Any zero-width parse successes thrown by
    # alternative parsers will flow on to a higher level.
    def parse string, options = {}
      raise ArgumentError if string.nil?
      error           = nil # for error reporting purposes will track which parseable gets farthest to the right before failing
      left_recursion  = nil # will also track any left recursion that we detect
      @alternatives.each do |parseable|
        begin
          result = parseable.memoizing_parse(string, options) # successful parse
          if left_recursion and left_recursion.continuation   # and we have a continuation
            continuation = left_recursion.continuation        # continuations are once-only, one-way tickets
            left_recursion = nil                              # set this to nil so as not to call it again without meaning to
            continuation.call(result)                         # so jump back to where we were before
          end
          return result
        rescue LeftRecursionException => e
          left_recursion = e

          # TODO:
          # it's not enough to just catch this kind of exception and remember
          # the last one
          # may need to accumulate these in an array
          # consider the example rule:
          #   :a, :a & :b | :a & :c | :a & :d | :b
          # the first option will raise a LeftRecursionException
          # the next option will raise for the same reason
          # the third likewise
          # finally we get to the fourth option, the first which might succeed
          # at that point we should have three continuations
          # we should try the first, falling back to the second and third if
          # necessary
          # on successfully retrying, need to start all over again and try all
          # the options again, just in case further recursion is possible
          # so it is quite complicated
          # the question is, is it more complicated than the other ways of
          # getting right-associativity into Walrat-generated parsers?
        rescue ParseError => e
          if error.nil?
            error = e
          else
            error = e unless error.rightmost?(e)
          end
        end
      end

      # should generally report the rightmost error
      raise ParseError.new('no valid alternatives while parsing "%s" (%s)' % [string, error.to_s],
                           :line_end => error.line_end,
                           :column_end => error.column_end)
    end

    def eql? other
      return false if not other.instance_of? ParsletChoice
      other_alternatives = other.alternatives
      return false if @alternatives.length != other_alternatives.length
      for i in 0..(@alternatives.length - 1)
        return false unless @alternatives[i].eql? other_alternatives[i]
      end
      true
    end

  protected

    # For determining equality.
    attr_reader :alternatives

  private

    def update_hash
      # fixed offset to avoid unwanted collisions with similar classes
      @hash = 30
      @alternatives.each { |parseable| @hash += parseable.hash }
    end

    # Appends another Parslet (or ParsletCombination) to the receiver and
    # returns the receiver.
    # Raises if parslet is nil.
    # Cannot use << as a method name because Ruby cannot parse it without
    # the self, and self is not allowed as en explicit receiver for private messages.
    def append next_parslet
      raise ArgumentError if next_parslet.nil?
      @alternatives << next_parslet.to_parseable
      update_hash
      self
    end
  end # class ParsletChoice
end # module Walrat
