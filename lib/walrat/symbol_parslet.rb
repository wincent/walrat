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
  # A SymbolParslet allows for evaluation of a parslet to be deferred until
  # runtime (or parse time, to be more precise).
  class SymbolParslet < Parslet
    attr_reader :hash

    def initialize symbol
      raise ArgumentError, 'nil symbol' if symbol.nil?
      @symbol = symbol

      # fixed offset to avoid collisions with @parseable objects
      @hash = @symbol.hash + 20
    end

    # SymbolParslets don't actually know what Grammar they are associated with
    # at the time of their definition. They expect the Grammar to be passed in
    # with the options hash under the ":grammar" key.
    # Raises if string is nil, or if the options hash does not include a
    # :grammar key.
    def parse string, options = {}
      raise ArgumentError if string.nil?
      raise ArgumentError unless options.has_key?(:grammar)
      grammar = options[:grammar]
      augmented_options = options.clone
      augmented_options[:rule_name] = @symbol
      augmented_options[:skipping_override] = grammar.skipping_overrides[@symbol] if grammar.skipping_overrides.has_key?(@symbol)
      result = grammar.rules[@symbol].memoizing_parse(string, augmented_options)
      grammar.wrap(result, @symbol)
    end

    # We override the to_s method as it can make parsing error messages more
    # readable. Instead of messages like this:
    #
    #   predicate not satisfied (expected "#<Walrat::SymbolParslet:0x10cd504>")
    #   while parsing "hello world"
    #
    # We can print messages like this:
    #
    #   predicate not satisfied (expected "rule: end_of_input") while parsing
    #   "hello world"
    def to_s
      'rule: ' + @symbol.to_s
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.instance_of? SymbolParslet and other.symbol == @symbol
    end

  protected

    # For equality comparisons.
    attr_reader :symbol
  end # class SymbolParslet
end # module Walrat
