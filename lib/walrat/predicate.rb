# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  # Predicates parse input without consuming it.
  # On success they throw a subclass-specific symbol (see the AndPredicate and
  # NotPredicate classes).
  # On failure they raise a ParseError.
  class Predicate
    include Walrat::ParsletCombining
    include Walrat::Memoizing

    attr_reader :hash

    # Raises if parseable is nil.
    def initialize parseable
      raise ArgumentError, 'nil parseable' if parseable.nil?
      @parseable = parseable

      # fixed offset to avoid collisions with @parseable objects
      @hash = @parseable.hash + hash_offset
    end

    def to_parseable
      self
    end

    def parse string, options = {}
      raise NotImplementedError # subclass responsibility
    end

    def eql? other
      other.instance_of? self.class and other.parseable.eql? @parseable
    end

  protected

    # for equality comparisons
    attr_reader :parseable

  private

    def hash_offset
      10
    end
  end
end # module Walrat
