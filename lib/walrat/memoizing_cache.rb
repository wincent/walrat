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
  # The MemoizingCache class memoizes the outcomes of parse operations. The
  # functionality is implemented as a separate class so as to minimize the
  # amount of "contamination" of other classes by memoizing code, and to allow
  # memoizing to be cleanly turned on or off at will. If a MemoizingCache is
  # passed to a Parslet, ParsletCombination or Predicate as a value for the
  # :memoizer key in the options hash passed to a parse method, the class
  # implementing that method will call the parse method on the cache rather
  # than proceeding normally. The cache will either propagate the previously
  # memoized result, or will defer back to the original class to obtain the
  # result. A circular dependency is avoided by setting the :skip_memoizer flag
  # in the options dictionary. If no MemoizingCache is passed then normal
  # program flow takes place.
  class MemoizingCache
    # Singleton class that serves as a default value for unset keys in a Hash.
    class NoValueForKey
      require 'singleton'
      include Singleton
    end

    def initialize
      # The results of parse operations are stored (memoized) in a cache, keyed
      # on a unique identifier comprising the Parslet, ParsletCombination or
      # Predicate used in the parse operation, the location of the operation
      # (the line_start and column_start), and the skipping override (if any).
      # The values may be:
      #
      #   - ParseErrors raised during parsing
      #   - SkippedSubstringExceptions raised during parsing
      #   - :ZeroWidthParseSuccess symbols thrown during parsing
      #   - :AndPredicateSuccess symbols thrown during parsing
      #   - :NotPredicateSuccess symbols thrown during parsing
      #   - String instances returned as parse results
      #   - MatchDataWrapper instance returned as parse results
      #   - Array instances containing ordered collections of parse results
      #   - Node subclass instances containing AST productions
      @cache = Hash.new NoValueForKey.instance
    end

    # The receiver checks whether there is already a stored result
    # corresponding to that a unique identifier that specifies the
    # "coordinates" of a parsing operation (location, parseable, skipping
    # override). If found propogates the result directly to the caller rather
    # than performing the parse method all over again. Here "propagation" means
    # re-raising parse errors, re-throwing symbols, and returning object
    # references. If not found, performs the parsing operation and stores the
    # result in the cache before propagating it.
    def parse string, options = {}
      raise ArgumentError if string.nil?

      # construct a unique identifier
      identifier = [options[:parseable], options[:line_start], options[:column_start]]
      identifier << options[:origin] if options.has_key? :origin
      identifier << options[:skipping_override] if options.has_key? :skipping_override

      if (result = @cache[identifier]) != NoValueForKey.instance
        if result.kind_of? Symbol
          throw result
        elsif result.kind_of? Exception
          raise result
        else
          return result
        end
      else
        # first time for this parseable/location/skipping_override (etc)
        # combination; capture result and propagate
        catch :NotPredicateSuccess do
          catch :AndPredicateSuccess do
            catch :ZeroWidthParseSuccess do
              begin
                options[:ignore_memoizer] = true

                # short-circuit left recursion here rather than infinite
                # looping
                if options[:parseable].kind_of? SymbolParslet
                  check_left_recursion(options[:parseable], options)
                  @last_seen_symbol_parslet             = options[:parseable]
                  @last_seen_symbol_parslet_location    = [options[:line_start], options[:column_start]]
                end

                return @cache[identifier] = options[:parseable].memoizing_parse(string, options)  # store and return
              rescue Exception => e
                raise @cache[identifier] = e                  # store and re-raise
              end
            end
            throw @cache[identifier] = :ZeroWidthParseSuccess # store and re-throw
          end
          throw @cache[identifier] = :AndPredicateSuccess     # store and re-throw
        end
        throw @cache[identifier] = :NotPredicateSuccess       # store and re-throw
      end
    end

    def check_left_recursion parseable, options = {}
      if parseable.kind_of? SymbolParslet and
         @last_seen_symbol_parslet == parseable and
         @last_seen_symbol_parslet_location == [options[:line_start], options[:column_start]]
        raise LeftRecursionException
      end
    end
  end # class MemoizingCache
end # module Walrat
