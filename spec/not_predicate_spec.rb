# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::NotPredicate do
  it 'complains on trying to parse a nil string' do
    expect do
      Walrat::NotPredicate.new('irrelevant').parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'can be compared for equality' do
    Walrat::NotPredicate.new('foo').
      should eql(Walrat::NotPredicate.new('foo'))      # same
    Walrat::NotPredicate.new('foo').
      should_not eql(Walrat::NotPredicate.new('bar'))  # different
    Walrat::NotPredicate.new('foo').
      should_not eql(Walrat::Predicate.new('foo'))     # different class
  end
end
