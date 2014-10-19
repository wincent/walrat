# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::Predicate do
  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::Predicate.new nil
    end.to raise_error(ArgumentError, /nil parseable/)
  end

  it 'complains if sent "parse" message' do
    # Predicate abstract superclass, "parse" is the responsibility of the
    # subclasses
    expect do
      Walrat::Predicate.new('foo').parse 'bar'
    end.to raise_error(NotImplementedError)
  end

  it 'should be able to compare predicates for equality' do
    Walrat::Predicate.new('foo').should eql(Walrat::Predicate.new('foo'))
    Walrat::Predicate.new('foo').should_not eql(Walrat::Predicate.new('bar'))
  end

  it '"and" and "not" predicates should yield different hashes even if initialized with the same "parseable"' do
    parseable = 'foo'.to_parseable
    p1 = Walrat::Predicate.new(parseable)
    p2 = Walrat::AndPredicate.new(parseable)
    p3 = Walrat::NotPredicate.new(parseable)

    p1.hash.should_not == p2.hash
    p2.hash.should_not == p3.hash
    p3.hash.should_not == p1.hash

    p1.should_not eql(p2)
    p2.should_not eql(p3)
    p3.should_not eql(p1)
  end
end
