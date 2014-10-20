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
    expect(Walrat::Predicate.new('foo')).to eql(Walrat::Predicate.new('foo'))
    expect(Walrat::Predicate.new('foo')).not_to eql(Walrat::Predicate.new('bar'))
  end

  it '"and" and "not" predicates should yield different hashes even if initialized with the same "parseable"' do
    parseable = 'foo'.to_parseable
    p1 = Walrat::Predicate.new(parseable)
    p2 = Walrat::AndPredicate.new(parseable)
    p3 = Walrat::NotPredicate.new(parseable)

    expect(p1.hash).not_to eq(p2.hash)
    expect(p2.hash).not_to eq(p3.hash)
    expect(p3.hash).not_to eq(p1.hash)

    expect(p1).not_to eql(p2)
    expect(p2).not_to eql(p3)
    expect(p3).not_to eql(p1)
  end
end
