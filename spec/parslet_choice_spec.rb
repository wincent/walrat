# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParsletChoice do
  before do
    @p1 = 'foo'.to_parseable
    @p2 = 'bar'.to_parseable
  end

  it 'hashes should be the same if initialized with the same parseables' do
    expect(Walrat::ParsletChoice.new(@p1, @p2).hash).to eq(Walrat::ParsletChoice.new(@p1, @p2).hash)
    expect(Walrat::ParsletChoice.new(@p1, @p2)).to eql(Walrat::ParsletChoice.new(@p1, @p2))
  end

  it 'hashes should (ideally) be different if initialized with different parseables' do
    expect(Walrat::ParsletChoice.new(@p1, @p2).hash).not_to eq(Walrat::ParsletChoice.new('baz'.to_parseable, 'abc'.to_parseable).hash)
    expect(Walrat::ParsletChoice.new(@p1, @p2)).not_to eql(Walrat::ParsletChoice.new('baz'.to_parseable, 'abc'.to_parseable))
  end

  it 'hashes should be different compared to other similar classes even if initialized with the same parseables' do
    expect(Walrat::ParsletChoice.new(@p1, @p2).hash).not_to eq(Walrat::ParsletSequence.new(@p1, @p2).hash)
    expect(Walrat::ParsletChoice.new(@p1, @p2)).not_to eql(Walrat::ParsletSequence.new(@p1, @p2))
  end

  it 'should be able to use Parslet Choice instances as keys in a hash' do
    hash = {}
    key1 = Walrat::ParsletChoice.new(@p1, @p2)
    key2 = Walrat::ParsletChoice.new('baz'.to_parseable, 'abc'.to_parseable)
    hash[:key1] = 'foo'
    hash[:key2] = 'bar'
    expect(hash[:key1]).to eq('foo')
    expect(hash[:key2]).to eq('bar')
  end
end
