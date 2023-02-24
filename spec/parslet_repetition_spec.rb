# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParsletRepetition do
  it 'raises if "parseable" argument is nil' do
    expect do
      Walrat::ParsletRepetition.new nil, 0
    end.to raise_error(ArgumentError, /nil parseable/)
  end

  it 'raises if "min" argument is nil' do
    expect do
      Walrat::ParsletRepetition.new 'foo'.to_parseable, nil
    end.to raise_error(ArgumentError, /nil min/)
  end

  it 'raises if passed nil string for parsing' do
    expect do
      Walrat::ParsletRepetition.new('foo'.to_parseable, 0).parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'should be able to match "zero or more" times (like "*" in regular expressions)' do
    parslet = Walrat::ParsletRepetition.new 'foo'.to_parseable, 0
    expect do
      parslet.parse 'bar'
    end.to throw_symbol(:ZeroWidthParseSuccess)                   # zero times
    expect(parslet.parse('foo')).to eq('foo')                          # one time
    expect(parslet.parse('foofoo')).to eq(['foo', 'foo'])              # two times
    expect(parslet.parse('foofoofoobar')).to eq(['foo', 'foo', 'foo']) # three times
  end

  it 'should be able to match "zero or one" times (like "?" in regular expressions)' do
    parslet = Walrat::ParsletRepetition.new 'foo'.to_parseable, 0, 1
    expect do
      parslet.parse 'bar'
    end.to throw_symbol(:ZeroWidthParseSuccess) # zero times
    expect(parslet.parse('foo')).to eq('foo')        # one time
    expect(parslet.parse('foofoo')).to eq('foo')     # stop at one time
  end

  it 'should be able to match "one or more" times (like "+" in regular expressions)' do
    parslet = Walrat::ParsletRepetition.new 'foo'.to_parseable, 1
    expect do
      parslet.parse 'bar'
    end.to raise_error(Walrat::ParseError)                        # zero times (error)
    expect(parslet.parse('foo')).to eq('foo')                          # one time
    expect(parslet.parse('foofoo')).to eq(['foo', 'foo'])              # two times
    expect(parslet.parse('foofoofoobar')).to eq(['foo', 'foo', 'foo']) # three times
  end

  it 'should be able to match "between X and Y" times (like {X, Y} in regular expressions)' do
    parslet = Walrat::ParsletRepetition.new 'foo'.to_parseable, 2, 3
    expect do
      parslet.parse 'bar'
    end.to raise_error(Walrat::ParseError)                        # zero times (error)
    expect do
      parslet.parse 'foo'
    end.to raise_error(Walrat::ParseError)                        # one time (error)
    expect(parslet.parse('foofoo')).to eq(['foo', 'foo'])              # two times
    expect(parslet.parse('foofoofoo')).to eq(['foo', 'foo', 'foo'])    # three times
    expect(parslet.parse('foofoofoofoo')).to eq(['foo', 'foo', 'foo']) # stop at three times
  end

  it 'matches should be greedy' do
    # here the ParsletRepetition should consume all the "foos", leaving nothing
    # for the final parslet
    parslet = Walrat::ParsletRepetition.new('foo'.to_parseable, 1) & 'foo'
    expect do
      parslet.parse 'foofoofoofoo'
    end.to raise_error(Walrat::ParseError)
  end

  it 'should be able to compare for equality' do
    expect(Walrat::ParsletRepetition.new('foo'.to_parseable, 1)).
      to eql(Walrat::ParsletRepetition.new('foo'.to_parseable, 1))
    expect(Walrat::ParsletRepetition.new('foo'.to_parseable, 1)).
      not_to eql(Walrat::ParsletRepetition.new('bar'.to_parseable, 1))
    expect(Walrat::ParsletRepetition.new('foo'.to_parseable, 1)).
      not_to eql(Walrat::ParsletRepetition.new('foo'.to_parseable, 2))
  end
end
