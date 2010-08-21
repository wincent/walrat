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
  # The ParsletCombining module, together with the ParsletCombination class and
  # its subclasses, provides simple container classes for encapsulating
  # relationships among Parslets. By storing this information outside of the
  # Parslet objects themselves their design is kept clean and they can become
  # immutable objects which are much more easily copied and shared among
  # multiple rules in a Grammar.
  module ParsletCombining
    # Convenience method.
    def memoizing_parse string, options = {}
      self.to_parseable.memoizing_parse string, options
    end

    # Convenience method.
    def parse string, options = {}
      self.to_parseable.parse string, options
    end

    # Defines a sequence of Parslets (or ParsletCombinations).
    # Returns a ParsletSequence instance.
    def sequence first, second, *others
      Walrat::ParsletSequence.new first.to_parseable,
        second.to_parseable, *others
    end

    # Shorthand for ParsletCombining.sequence(first, second).
    def &(next_parslet)
      self.sequence self, next_parslet
    end

    # Defines a sequence of Parslets similar to the sequence method but with
    # the difference that the contents of array results from the component
    # parslets will be merged into a single array rather than being added as
    # arrays. To illustrate:
    #
    #   'foo' & 'bar'.one_or_more   # returns results like ['foo', ['bar', 'bar', 'bar']]
    #   'foo' >> 'bar'.one_or_more  # returns results like ['foo', 'bar', 'bar', 'bar']
    #
    def merge first, second, *others
      Walrat::ParsletMerge.new first.to_parseable,
        second.to_parseable, *others
    end

    # Shorthand for ParsletCombining.sequence(first, second)
    def >>(next_parslet)
      self.merge self, next_parslet
    end

    # Defines a choice of Parslets (or ParsletCombinations).
    # Returns a ParsletChoice instance.
    def choice left, right, *others
      Walrat::ParsletChoice.new left.to_parseable,
        right.to_parseable, *others
    end

    # Shorthand for ParsletCombining.choice(left, right)
    def |(alternative_parslet)
      self.choice self, alternative_parslet
    end

    # Defines a repetition of the supplied Parslet (or ParsletCombination).
    # Returns a ParsletRepetition instance.
    def repetition parslet, min, max
      Walrat::ParsletRepetition.new parslet.to_parseable, min, max
    end

    # Shorthand for ParsletCombining.repetition.
    def repeat min = nil, max = nil
      self.repetition self, min, max
    end

    def repetition_with_default parslet, min, max, default
      Walrat::ParsletRepetitionDefault.new parslet.to_parseable, min,
        max, default
    end

    def repeat_with_default min = nil, max = nil, default = nil
      self.repetition_with_default self, min, max, default
    end

    # Shorthand for ParsletCombining.repetition(0, 1).
    # This method optionally takes a single parameter specifying what object
    # should be returned as a placeholder when there are no matches; this is
    # useful for packing into ASTs where it may be better to parse an empty
    # Array rather than nil. The specified object is cloned and returned in the
    # event that there are no matches. As a convenience, the specified object
    # is automatically extended using the LocationTracking module (this is a
    # convenience so that you can specify empty Arrays, "[]", rather than
    # explicitly passing an "ArrayResult.new")
    def optional default_return_value = NoParameterMarker.instance
      if default_return_value == NoParameterMarker.instance
        self.repeat 0, 1 # default behaviour
      else
        self.repeat_with_default 0, 1, default_return_value
      end
    end

    # Alternative to optional.
    def zero_or_one
      self.optional
    end

    # possible synonym "star"
    def zero_or_more default_return_value = NoParameterMarker.instance
      if default_return_value == NoParameterMarker.instance
        self.repeat 0 # default behaviour
      else
        self.repeat_with_default 0, nil, default_return_value
      end
    end

    # possible synonym "plus"
    def one_or_more
      self.repeat 1
    end

    # Parsing Expression Grammar support.
    # Succeeds if parslet succeeds but consumes no input (throws an
    # :AndPredicateSuccess symbol).
    def and_predicate parslet
      Walrat::AndPredicate.new parslet.to_parseable
    end

    # Shorthand for and_predicate
    # Strictly speaking, this shorthand breaks with established Ruby practice
    # that "?" at the end of a method name should indicate a method that
    # returns true or false.
    def and?
      self.and_predicate self
    end

    # Parsing Expression Grammar support.
    # Succeeds if parslet fails (throws a :NotPredicateSuccess symbol).
    # Fails if parslet succeeds (raise a ParseError).
    # Consumes no output.
    # This method will almost invariably be used in conjuntion with the &
    # operator, like this:
    #       rule :foo, :p1 & :p2.not_predicate
    #       rule :foo, :p1 & :p2.not!
    def not_predicate parslet
      Walrat::NotPredicate.new parslet.to_parseable
    end

    # Shorthand for not_predicate.
    # Strictly speaking, this shorthand breaks with established Ruby practice
    # that "!" at the end of a method name should indicate a destructive
    # behaviour on (mutation of) the receiver.
    def not!
      self.not_predicate self
    end

    # Succeeds if parsing succeeds, consuming the output, but doesn't actually
    # return anything.
    #
    # This is for elements which are required but which shouldn't appear in the
    # final AST.
    def omission parslet
      Walrat::ParsletOmission.new parslet.to_parseable
    end

    # Shorthand for ParsletCombining.omission
    def skip
      self.omission self
    end
  end # module ParsletCombining
end # module Walrat
