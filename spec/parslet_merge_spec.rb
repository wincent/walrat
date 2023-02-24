# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParsletMerge do
  it 'should be able to compare for equality' do
    expect(Walrat::ParsletMerge.new('foo', 'bar')).to eql(Walrat::ParsletMerge.new('foo', 'bar'))
    expect(Walrat::ParsletMerge.new('foo', 'bar')).not_to eql(Walrat::ParsletOmission.new('foo')) # wrong class
  end

  it 'ParsletMerge and ParsletSequence hashs should not match even if created using the same parseable instances' do
    parseable1 = 'foo'.to_parseable
    parseable2 = 'bar'.to_parseable
    p1 = Walrat::ParsletMerge.new(parseable1, parseable2)
    p2 = Walrat::ParsletSequence.new(parseable1, parseable2)
    expect(p1.hash).not_to eq(p2.hash)
    expect(p1).not_to eql(p2)
  end
end
