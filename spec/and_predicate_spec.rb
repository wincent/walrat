# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Walrat::AndPredicate do
  subject { Walrat::AndPredicate.new('foo') }

  it 'complains on trying to parse a nil string' do
    expect do
      subject.parse nil
    end.to raise_error(ArgumentError)
  end

  it 'is able to compare for equality' do
    should eql(Walrat::AndPredicate.new('foo'))     # same
    should_not eql(Walrat::AndPredicate.new('bar')) # different
    should_not eql(Walrat::Predicate.new('foo'))    # same but different class
  end
end
