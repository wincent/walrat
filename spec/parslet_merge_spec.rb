# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParsletMerge do
  it 'should be able to compare for equality' do
    Walrat::ParsletMerge.new('foo', 'bar').should eql(Walrat::ParsletMerge.new('foo', 'bar'))
    Walrat::ParsletMerge.new('foo', 'bar').should_not eql(Walrat::ParsletOmission.new('foo')) # wrong class
  end

  it 'ParsletMerge and ParsletSequence hashs should not match even if created using the same parseable instances' do
    parseable1 = 'foo'.to_parseable
    parseable2 = 'bar'.to_parseable
    p1 = Walrat::ParsletMerge.new(parseable1, parseable2)
    p2 = Walrat::ParsletSequence.new(parseable1, parseable2)
    p1.hash.should_not == p2.hash
    p1.should_not eql(p2)
  end
end
