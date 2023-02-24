# encoding: utf-8
# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::StringEnumerator do
  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::StringEnumerator.new nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'returns characters one by one until end of string, then return nil' do
    enumerator = Walrat::StringEnumerator.new('hello')
    expect(enumerator.next).to eq('h')
    expect(enumerator.next).to eq('e')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('o')
    expect(enumerator.next).to be_nil
  end

  it 'is Unicode-aware (UTF-8)' do
    enumerator = Walrat::StringEnumerator.new('€ cañon')
    expect(enumerator.next).to eq('€')
    expect(enumerator.next).to eq(' ')
    expect(enumerator.next).to eq('c')
    expect(enumerator.next).to eq('a')
    expect(enumerator.next).to eq('ñ')
    expect(enumerator.next).to eq('o')
    expect(enumerator.next).to eq('n')
    expect(enumerator.next).to be_nil
  end

  # this was a bug
  it 'continues past newlines' do
    enumerator = Walrat::StringEnumerator.new("hello\nworld")
    expect(enumerator.next).to eq('h')
    expect(enumerator.next).to eq('e')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('o')
    expect(enumerator.next).to eq("\n") # was returning nil here
    expect(enumerator.next).to eq('w')
    expect(enumerator.next).to eq('o')
    expect(enumerator.next).to eq('r')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('d')
  end

  it 'can recall the last character using the "last" method' do
    enumerator = Walrat::StringEnumerator.new('h€llo')
    expect(enumerator.last).to eq(nil) # nothing scanned yet
    expect(enumerator.next).to eq('h') # advance
    expect(enumerator.last).to eq(nil) # still no previous character
    expect(enumerator.next).to eq('€') # advance
    expect(enumerator.last).to eq('h')
    expect(enumerator.next).to eq('l') # advance
    expect(enumerator.last).to eq('€')
    expect(enumerator.next).to eq('l') # advance
    expect(enumerator.last).to eq('l')
    expect(enumerator.next).to eq('o') # advance
    expect(enumerator.last).to eq('l')
    expect(enumerator.next).to eq(nil) # nothing left to scan
    expect(enumerator.last).to eq('o')
    expect(enumerator.last).to eq('o') # didn't advance, so should return the same
  end
end
