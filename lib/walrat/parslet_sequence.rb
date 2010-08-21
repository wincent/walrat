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
  class ParsletSequence < ParsletCombination
    attr_reader :hash

    # first and second may not be nil.
    def initialize first, second, *others
      raise ArgumentError if first.nil?
      raise ArgumentError if second.nil?
      @components = [first, second] + others
      update_hash
    end

    # Override so that sequences are appended to an existing sequence:
    # Consider the following example:
    #
    #     A & B
    #
    # This constitutes a single sequence:
    #
    #     (A & B)
    #
    # If we then make this a three-element sequence:
    #
    #     A & B & C
    #
    # We are effectively creating an nested sequence containing the original
    # sequence and an additional element:
    #
    #     ((A & B) & C)
    #
    # Although such a nested sequence is correctly parsed it produces unwanted
    # nesting in the results because instead of returning a one-dimensional
    # array of results:
    #
    #     [a, b, c]
    #
    # It returns a nested array:
    #
    #     [[a, b], c]
    #
    # The solution to this unwanted nesting is to allowing appending to an
    # existing sequence by using the private "append" method.
    #
    # This ensures that:
    #
    #     A & B & C
    #
    # Translates to a single sequence:
    #
    #     (A & B & C)
    #
    # And a single, uni-dimensional results array:
    #
    #     [a, b, c]
    def &(next_parslet)
      append next_parslet
    end

    SKIP_FIRST  = true
    NO_SKIP     = false

    def parse string, options = {}
      parse_common NO_SKIP, string, options
    end

    def parse_remainder string, options = {}
      parse_common SKIP_FIRST, string, options
    end

    def parse_common skip_first, string, options = {}
      raise ArgumentError if string.nil?
      state           = ParserState.new(string, options)
      last_caught     = nil   # keep track of the last kind of throw to be caught
      left_recursion  = false # keep track of whether left recursion was detected

      @components.each_with_index do |parseable, index|
        if index == 0 # for first component only
          if skip_first
            next
          end
          begin
            check_left_recursion(parseable, options)
          rescue LeftRecursionException => e
            left_recursion  = true
            continuation    = nil
            value           = callcc { |c| continuation = c }
            if value == continuation        # first time that we're here
              e.continuation = continuation # pack continuation into exception
              raise e                       # and propagate
            else
              grammar   = state.options[:grammar]
              rule_name = state.options[:rule_name]
              state.parsed grammar.wrap(value, rule_name)
              next
            end
          end
        end

        catch :ProcessNextComponent do
          catch :NotPredicateSuccess do
            catch :AndPredicateSuccess do
              catch :ZeroWidthParseSuccess do
                begin
                  parsed = parseable.memoizing_parse state.remainder, state.options
                  state.parsed parsed
                rescue SkippedSubstringException => e
                  state.skipped e
                rescue ParseError => e
                  # failed, will try to skip; save original error in case
                  # skipping fails
                  if options.has_key?(:skipping_override)
                    skipping_parslet = options[:skipping_override]
                  elsif options.has_key?(:skipping)
                    skipping_parslet = options[:skipping]
                  else
                    skipping_parslet = nil
                  end
                  raise e if skipping_parslet.nil?  # no skipper defined, raise original error
                  begin
                    # guard against self references (possible infinite recursion) here?
                    parsed = skipping_parslet.memoizing_parse state.remainder, state.options
                    state.skipped(parsed)
                    redo              # skipping succeeded, try to redo
                  rescue ParseError
                    raise e           # skipping didn't help either, raise original error
                  end
                end
                last_caught = nil

                # can't use "next" here because it would only break out of
                # innermost "do" rather than continuing the iteration
                throw :ProcessNextComponent
              end
              last_caught = :ZeroWidthParseSuccess
              throw :ProcessNextComponent
            end
            last_caught = :AndPredicateSuccess
            throw :ProcessNextComponent
          end
          last_caught = :NotPredicateSuccess
        end
      end

      if left_recursion
        results = recurse(state)
      else
        results = state.results
      end

      return results if skip_first

      if results.respond_to? :empty? and results.empty? and last_caught
        throw last_caught
      else
        results
      end
    end

    # Left-recursion helper
    def recurse state
      return state.results if state.remainder == '' # further recursion is not possible
      new_state = ParserState.new state.remainder, state.options
      last_successful_result = nil
      while state.remainder != ''
        begin
          new_results = parse_remainder new_state.remainder, new_state.options
          new_state.parsed new_results
          last_successful_result = ArrayResult[last_successful_result || state.results, new_results]
        rescue ParseError
          break
        end
      end
      last_successful_result || state.results
    end

    def eql?(other)
      return false if not other.instance_of? ParsletSequence
      other_components = other.components
      return false if @components.length != other_components.length
      for i in 0..(@components.length - 1)
        return false unless @components[i].eql? other_components[i]
      end
      true
    end

  protected

    # For determining equality.
    attr_reader :components

  private

    def hash_offset
      40
    end

    def update_hash
      # fixed offset to avoid unwanted collisions with similar classes
      @hash = hash_offset
      @components.each { |parseable| @hash += parseable.hash }
    end

    # Appends another Parslet, ParsletCombination or Predicate to the receiver
    # and returns the receiver.
    #
    # Raises if next_parslet is nil.
    # Cannot use << as a method name because Ruby cannot parse it without the
    # self, and self is not allowed as en explicit receiver for private
    # messages.
    def append next_parslet
      raise ArgumentError if next_parslet.nil?
      @components << next_parslet.to_parseable
      update_hash
      self
    end
  end # class ParsletSequence
end # module Walrat
