# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

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
      to_parseable.memoizing_parse string, options
    end

    # Convenience method.
    def parse string, options = {}
      to_parseable.parse string, options
    end

    # Defines a sequence of Parslets (or ParsletCombinations).
    # Returns a ParsletSequence instance.
    def sequence first, second, *others
      ParsletSequence.new first.to_parseable,
        second.to_parseable, *others
    end

    # Shorthand for ParsletCombining.sequence(first, second).
    def &(next_parslet)
      sequence self, next_parslet
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
      ParsletMerge.new first.to_parseable,
        second.to_parseable, *others
    end

    # Shorthand for ParsletCombining.sequence(first, second)
    def >>(next_parslet)
      merge self, next_parslet
    end

    # Defines a choice of Parslets (or ParsletCombinations).
    # Returns a ParsletChoice instance.
    def choice left, right, *others
      ParsletChoice.new left.to_parseable,
        right.to_parseable, *others
    end

    # Shorthand for ParsletCombining.choice(left, right)
    def |(alternative_parslet)
      choice self, alternative_parslet
    end

    # Defines a repetition of the supplied Parslet (or ParsletCombination).
    # Returns a ParsletRepetition instance.
    def repetition parslet, min, max
      ParsletRepetition.new parslet.to_parseable, min, max
    end

    # Shorthand for ParsletCombining.repetition.
    def repeat min = nil, max = nil
      repetition self, min, max
    end

    def repetition_with_default parslet, min, max, default
      ParsletRepetitionDefault.new parslet.to_parseable, min,
        max, default
    end

    def repeat_with_default min = nil, max = nil, default = nil
      repetition_with_default self, min, max, default
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
        repeat 0, 1 # default behaviour
      else
        repeat_with_default 0, 1, default_return_value
      end
    end

    # Alternative to optional.
    def zero_or_one
      optional
    end

    # possible synonym "star"
    def zero_or_more default_return_value = NoParameterMarker.instance
      if default_return_value == NoParameterMarker.instance
        repeat 0 # default behaviour
      else
        repeat_with_default 0, nil, default_return_value
      end
    end

    # possible synonym "plus"
    def one_or_more
      repeat 1
    end

    # Parsing Expression Grammar support.
    # Succeeds if parslet succeeds but consumes no input (throws an
    # :AndPredicateSuccess symbol).
    def and_predicate parslet
      AndPredicate.new parslet.to_parseable
    end

    # Shorthand for and_predicate
    # Strictly speaking, this shorthand breaks with established Ruby practice
    # that "?" at the end of a method name should indicate a method that
    # returns true or false.
    def and?
      and_predicate self
    end

    # Parsing Expression Grammar support.
    # Succeeds if parslet fails (throws a :NotPredicateSuccess symbol).
    # Fails if parslet succeeds (raise a ParseError).
    # Consumes no output.
    # This method will almost invariably be used in conjuntion with the &
    # operator, like this:
    #       rule :foo, :p1 & :p2.not_predicate
    #       rule :foo, :p1 & :p2.not!
    def not_predicate parslet = self
      NotPredicate.new parslet.to_parseable
    end

    # Shorthand for not_predicate.
    # Strictly speaking, this shorthand breaks with established Ruby practice
    # that "!" at the end of a method name should indicate a destructive
    # behaviour on (mutation of) the receiver.
    def not!
      not_predicate self
    end

    # Succeeds if parsing succeeds, consuming the output, but doesn't actually
    # return anything.
    #
    # This is for elements which are required but which shouldn't appear in the
    # final AST.
    def omission parslet
      ParsletOmission.new parslet.to_parseable
    end

    # Shorthand for ParsletCombining.omission
    def skip
      omission self
    end
  end # module ParsletCombining
end # module Walrat
