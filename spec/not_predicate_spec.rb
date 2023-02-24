# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::NotPredicate do
  it 'complains on trying to parse a nil string' do
    expect do
      Walrat::NotPredicate.new('irrelevant').parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'can be compared for equality' do
    expect(Walrat::NotPredicate.new('foo')).
      to eql(Walrat::NotPredicate.new('foo'))      # same
    expect(Walrat::NotPredicate.new('foo')).
      not_to eql(Walrat::NotPredicate.new('bar'))  # different
    expect(Walrat::NotPredicate.new('foo')).
      not_to eql(Walrat::Predicate.new('foo'))     # different class
  end
end
