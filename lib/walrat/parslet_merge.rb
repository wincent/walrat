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
  class ParsletMerge < ParsletSequence
    def parse string, options = {}
      raise ArgumentError if string.nil?
      state       = ParserState.new string, options
      last_caught = nil # keep track of the last kind of throw to be caught
      @components.each do |parseable|
        catch :ProcessNextComponent do
          catch :NotPredicateSuccess do
            catch :AndPredicateSuccess do
              catch :ZeroWidthParseSuccess do
                begin
                  parsed = parseable.memoizing_parse state.remainder, state.options
                  if parsed.respond_to? :each
                    parsed.each { |element| state.parsed element }
                  else
                    state.parsed(parsed)
                  end
                rescue SkippedSubstringException => e
                  state.skipped(e)
                # rescue ParseError => e # failed, will try to skip; save original error in case skipping fails
                #   if options.has_key?(:skipping_override) : skipping_parslet = options[:skipping_override]
                #   elsif options.has_key?(:skipping)       : skipping_parslet = options[:skipping]
                #   else                                      skipping_parslet = nil
                #   end
                #   raise e if skipping_parslet.nil?        # no skipper defined, raise original error
                #   begin
                #     # guard against self references (possible infinite recursion) here?
                #     parsed = skipping_parslet.memoizing_parse(state.remainder, state.options)
                #     state.skipped(parsed)
                #     redo              # skipping succeeded, try to redo
                #   rescue ParseError
                #     raise e           # skipping didn't help either, raise original error
                #   end
                end
                last_caught = nil
                throw :ProcessNextComponent # can't use "next" here because it will only break out of innermost "do"
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

      if state.results.respond_to? :empty? and state.results.empty? and
       throw last_caught
      else
        state.results
      end
    end

    def eql?(other)
      return false if not other.instance_of? ParsletMerge
      other_components = other.components
      return false if @components.length != other_components.length
      for i in 0..(@components.length - 1)
        return false unless @components[i].eql? other_components[i]
      end
      true
    end

  private

    def hash_offset
      53
    end
  end # class ParsletMerge
end # module Walrat
