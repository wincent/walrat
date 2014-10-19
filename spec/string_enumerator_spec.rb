# encoding: utf-8
# Copyright 2007-2014 Greg Hurrell. All rights reserved.
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
    enumerator.next.should == 'h'
    enumerator.next.should == 'e'
    enumerator.next.should == 'l'
    enumerator.next.should == 'l'
    enumerator.next.should == 'o'
    enumerator.next.should be_nil
  end

  it 'is Unicode-aware (UTF-8)' do
    enumerator = Walrat::StringEnumerator.new('€ cañon')
    enumerator.next.should == '€'
    enumerator.next.should == ' '
    enumerator.next.should == 'c'
    enumerator.next.should == 'a'
    enumerator.next.should == 'ñ'
    enumerator.next.should == 'o'
    enumerator.next.should == 'n'
    enumerator.next.should be_nil
  end

  # this was a bug
  it 'continues past newlines' do
    enumerator = Walrat::StringEnumerator.new("hello\nworld")
    enumerator.next.should == 'h'
    enumerator.next.should == 'e'
    enumerator.next.should == 'l'
    enumerator.next.should == 'l'
    enumerator.next.should == 'o'
    enumerator.next.should == "\n" # was returning nil here
    enumerator.next.should == 'w'
    enumerator.next.should == 'o'
    enumerator.next.should == 'r'
    enumerator.next.should == 'l'
    enumerator.next.should == 'd'
  end

  it 'can recall the last character using the "last" method' do
    enumerator = Walrat::StringEnumerator.new('h€llo')
    enumerator.last.should == nil # nothing scanned yet
    enumerator.next.should == 'h' # advance
    enumerator.last.should == nil # still no previous character
    enumerator.next.should == '€' # advance
    enumerator.last.should == 'h'
    enumerator.next.should == 'l' # advance
    enumerator.last.should == '€'
    enumerator.next.should == 'l' # advance
    enumerator.last.should == 'l'
    enumerator.next.should == 'o' # advance
    enumerator.last.should == 'l'
    enumerator.next.should == nil # nothing left to scan
    enumerator.last.should == 'o'
    enumerator.last.should == 'o' # didn't advance, so should return the same
  end
end
