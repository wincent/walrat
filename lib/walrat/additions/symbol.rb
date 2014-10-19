# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

class Symbol
  include Walrat::ParsletCombining

  # Returns a SymbolParslet based on the receiver.
  # Symbols can be used in Grammars when specifying rules and productions to
  # refer to other rules and productions that have not been defined yet.
  # They can also be used to allow self-references within rules and productions
  # (recursion); for example:
  #
  #   rule :thing, :thing & :thing.optional & :other_thing
  #
  # Basically these SymbolParslets allow deferred evaluation of a rule or
  # production (deferred until parsing takes place) rather than being evaluated
  # at the time a rule or production is defined.
  def to_parseable
    Walrat::SymbolParslet.new self
  end
end # class Symbol
