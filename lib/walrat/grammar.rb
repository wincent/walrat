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
require 'walrat/additions/string.rb'

module Walrat
  class Grammar
    class << self
      # Lazy reader for the rules hash.
      #
      # Initializes the hash the first time it is accessed.
      def rules
        @rules or @rules = Hash.new do |hash, key|
          raise "no rule for key '#{key}'"
        end
      end

      # Lazy reader for the productions hash.
      #
      # Initializes the hash the first time it is accessed.
      def productions
        @productions or @productions = Hash.new do |hash, key|
          raise "no production for key '#{key}'"
        end
      end

      # Lazy reader for the skipping overrides hash.
      #
      # Initializes the hash the first time it is accessed.
      def skipping_overrides
        @skipping_overrides or @skipping_overrides = Hash.new do |hash, key|
          raise "no skipping override for key '#{key}'"
        end
      end

      # Sets the starting symbol.
      #
      # @param [Symbol] symbol a symbol which refers to a rule
      def starting_symbol symbol
        raise ArgumentError, 'starting symbol already set' if @starting_symbol
        @starting_symbol = symbol
      end

      # Returns the starting symbol.
      #
      # Note that the "starting_symbol" method can't be used as an accessor
      # because it is already used as part of the grammar-definition DSL.
      def start_rule
        @starting_symbol
      end

      # Sets the default parslet that is used for skipping inter-token
      # whitespace, and can be used to override the default on a rule-by-rule
      # basis.
      #
      # This allows for simpler grammars which do not need to explicitly put
      # optional whitespace parslets (or any other kind of parslet) between
      # elements.
      #
      # There are two modes of operation for this method. In the first mode
      # (when only one parameter is passed) the rule_or_parslet parameter is
      # used to define the default parslet for inter-token skipping.
      # rule_or_parslet must refer to a rule which itself is a Parslet or
      # ParsletCombination and which is responsible for skipping. Note that the
      # ability to pass an arbitrary parslet means that the notion of what
      # consitutes the "whitespace" that should be skipped is completely
      # flexible. Raises if a default skipping parslet has already been set.
      #
      # In the second mode of operation (when two parameters are passed) the
      # rule_or_parslet parameter is interpreted to be the rule to which an
      # override should be applied, where the parslet parameter specifies the
      # parslet to be used in this case. If nil is explicitly passed then this
      # overrides the default parslet; no parslet will be used for the purposes
      # of inter-token skipping. Raises if an override has already been set for
      # the named rule.
      #
      # The inter-token parslet is passed inside the "options" hash when
      # invoking the "parse" methods. Any parser which fails will retry after
      # giving this inter-token parslet a chance to consume and discard
      # intervening whitespace.
      #
      # The initial, conservative implementation only performs this fallback
      # skipping for ParsletSequence and ParsletRepetition combinations.
      #
      # Raises if rule_or_parslet is nil.
      def skipping rule_or_parslet, parslet = NoParameterMarker.instance
        raise ArgumentError, 'nil rule_or_parslet' if rule_or_parslet.nil?
        if parslet == NoParameterMarker.instance
          # first mode of operation: set default parslet
          raise 'default skipping parslet already set' if @skipping
          @skipping = rule_or_parslet
        else
          # second mode of operation: override default case
          raise ArgumentError,
            "skipping override already set for rule '#{rule_or_parslet}'" if
            skipping_overrides.has_key? rule_or_parslet
          raise ArgumentError,
            "non-existent rule '#{rule_or_parslet}'" unless
            rules.has_key? rule_or_parslet
          skipping_overrides[rule_or_parslet] = parslet
        end
      end

      # Returns the default skipping rule.
      #
      # Note that we can't use "skipping" as the accessor method here because
      # it is already used as part of the grammar-definition DSL.
      def default_skipping_rule
        @skipping
      end

      # Defines a rule and stores it
      #
      # Expects an object that responds to the parse message, such as a Parslet
      # or ParsletCombination. As this is intended to work with Parsing
      # Expression Grammars, each rule may only be defined once. Defining a
      # rule more than once will raise an ArgumentError.
      def rule symbol, parseable
        raise ArgumentError, 'nil symbol' if symbol.nil?
        raise ArgumentError, 'nil parseable' if parseable.nil?
        raise ArgumentError,
          "rule '#{symbol}' already defined" if rules.has_key? symbol
        rules[symbol] = parseable
      end

      # Dynamically creates a Node subclass inside the namespace of the current
      # grammar.
      #
      # This is used to create classes in a class hierarchy where no custom
      # behavior is required and therefore no actual file with an impementation
      # need be provided; an example from the Walrus grammar:
      #
      #     module Walrus
      #       class Grammar < Walrat::Grammar
      #         class Literal < Walrat::Node
      #           class StringLiteral < Literal
      #             class DoubleQuotedStringLiteral < StringLiteral
      #
      # In this example hiearchy the "Literal" class has custom behavior which
      # is shared by all subclasses, and the custom behavior is implemented in
      # the file "walrus/grammar/literal". The subclasses, however, have no
      # custom behavior and no associated file. They are dynamically
      # synthesized when the Walrus::Grammar class is first evaluated.
      def node new_class_name, parent_class = Node
        raise ArgumentError, 'nil new_class_name' if new_class_name.nil?
        new_class_name = new_class_name.to_s.to_class_name # camel-case
        unless parent_class.kind_of? Class
          parent_class = const_get parent_class.to_s.to_class_name
        end
        const_set new_class_name, Class.new(parent_class)
      end

      # Specifies that a Node subclass will be used to encapsulate results
      # for the rule identified by the symbol, rule_name. The class name is
      # derived by converting the rule_name to camel-case.
      #
      # If no additional params are supplied then the class is assumed to
      # accept a single  parameter named "lexeme" in its initialize method.
      #
      # If additional params are supplied then the class is expected to
      # accept the named params in its initialize method.
      #
      # As a convenience, the params will be sent to the specified class using
      # the "production" method, which sets up an appropriate initializer.
      #
      # For example:
      #
      #     # accepts a single parameter, "lexeme"
      #     production :symbol_literal
      #
      #     # accepts a single parameter, "content"
      #     production :multiline_comment, :content
      #
      #     # accepts three parameters, "identifier", "params" and "content"
      #     production :block_directive, :identifier, :params, :content
      #
      def production rule_name, *results
        raise ArgumentError, 'nil rule_name' if rule_name.nil?
        raise ArgumentError,
          "production already defined for rule '#{rule_name}'" if
          productions.has_key?(rule_name)
        raise ArgumentError, "non-existent rule '#{rule_name}'" unless
          rules.has_key?(rule_name)
        results = results.empty? ? [:lexeme] : results
        const_get(rule_name.to_s.to_class_name).production *results
        productions[rule_name] = results
      end

      # This method is called by the ParsletSequence and SymbolParslet classes
      # to possibly wrap a parse result in a production node.
      def wrap result, rule_name
        if productions.has_key? rule_name.to_sym
          node_class          = const_get rule_name.to_s.to_class_name
          param_count         = productions[rule_name.to_sym].length
          if param_count == 1
            node              = node_class.new result
          else
            node              = node_class.new *result
          end
          node.start          = (result.outer_start or result.start)              # propagate the start information
          node.end            = (result.outer_end or result.end)                  # and the end information
          node.source_text    = (result.outer_source_text or result.source_text)  # and the original source text
          node
        else
          result.start        = result.outer_start if result.outer_start
          result.end          = result.outer_end if result.outer_end
          result.source_text  = result.source_text if result.outer_source_text
          result
        end
      end
    end

    attr_accessor :memoizing

    def initialize
      @memoizing = true
    end

    # TODO: consider making grammars copiable (could be used in threaded context then)
    #def initialize_copy(from); end
    #def clone; end
    #def dupe; end

    # Starts with starting_symbol.
    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      raise 'starting symbol not defined' if self.class.start_rule.nil?
      options[:grammar]       = self.class
      options[:rule_name]     = self.class.start_rule
      options[:skipping]      = self.class.default_skipping_rule
      options[:line_start]    = 0 # "richer" information (more human-friendly) than that provided in "location"
      options[:column_start]  = 0 # "richer" information (more human-friendly) than that provided in "location"
      options[:memoizer]      = MemoizingCache.new if @memoizing
      self.class.start_rule.to_parseable.memoizing_parse string, options
    end

    # TODO: pretty print method?
  end # class Grammar
end # module Walrus
