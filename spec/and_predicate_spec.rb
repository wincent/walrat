# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::AndPredicate do
  subject { Walrat::AndPredicate.new('foo') }

  it 'complains on trying to parse a nil string' do
    expect do
      subject.parse nil
    end.to raise_error(ArgumentError)
  end

  it 'is able to compare for equality' do
    is_expected.to eql(Walrat::AndPredicate.new('foo'))     # same
    is_expected.not_to eql(Walrat::AndPredicate.new('bar')) # different
    is_expected.not_to eql(Walrat::Predicate.new('foo'))    # same but different class
  end
end
