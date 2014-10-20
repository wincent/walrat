# encoding: utf-8
# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe String do
  describe '#to_class_name' do
    it 'works with require names' do
      expect('foo_bar'.to_class_name).to eq('FooBar')
    end

    it 'works with a single-letter' do
      expect('f'.to_class_name).to eq('F')
    end

    it 'works with double-underscores' do
      expect('foo__bar'.to_class_name).to eq('FooBar')
    end

    it 'works with terminating double-underscores' do
      expect('foo__'.to_class_name).to eq('Foo')
    end
  end
end

describe 'iterating over a string' do
  # formerly a bug: the StringScanner used under the covers was returning nil
  # (stopping) on hitting a newline
  it 'should be able to iterate over strings containing newlines' do
    chars = []
    "hello\nworld".each_char { |c| chars << c }
    expect(chars).to eq(['h', 'e', 'l', 'l', 'o', "\n",
      'w', 'o', 'r', 'l', 'd'])
  end
end

describe 'working with Unicode strings' do
  before do
    # € (Euro) is a three-byte UTF-8 glyph: "\342\202\254"
    @string = 'Unicode €!'
  end

  it 'the "each_char" method should work with multibyte characters' do
    chars = []
    @string.each_char { |c| chars << c }
    expect(chars).to eq(['U', 'n', 'i', 'c', 'o', 'd', 'e', ' ', '€', '!'])
  end

  it 'the "chars" method should work with multibyte characters' do
    expect(@string.chars.to_a).to eq(['U', 'n', 'i', 'c', 'o', 'd', 'e', ' ', '€', '!'])
  end

  it 'should be able to use "enumerator" convenience method to get a string enumerator' do
    enumerator = 'hello€'.enumerator
    expect(enumerator.next).to eq('h')
    expect(enumerator.next).to eq('e')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('l')
    expect(enumerator.next).to eq('o')
    expect(enumerator.next).to eq('€')
    expect(enumerator.next).to be_nil
  end

  it 'the "jlength" method should correctly report the number of characters in a string' do
    expect(@string.jlength).to  eq(10)
    expect("€".jlength).to      eq(1)  # three bytes long, but one character
  end
end

# For more detailed specification of the StringParslet behaviour see
# string_parslet_spec.rb.
describe 'using shorthand to get StringParslets from String instances' do
  it 'chaining two Strings with the "&" operator should yield a two-element sequence' do
    sequence = 'foo' & 'bar'
    expect(sequence.parse('foobar')).to eq(['foo', 'bar'])
    expect { sequence.parse('no match') }.to raise_error(Walrat::ParseError)
  end

  it 'chaining three Strings with the "&" operator should yield a three-element sequence' do
    sequence = 'foo' & 'bar' & '...'
    expect(sequence.parse('foobar...')).to eq(['foo', 'bar', '...'])
    expect { sequence.parse('no match') }.to raise_error(Walrat::ParseError)
  end

  it 'alternating two Strings with the "|" operator should yield a single string' do
    sequence = 'foo' | 'bar'
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('foobar')).to eq('foo')
    expect(sequence.parse('bar')).to eq('bar')
    expect { sequence.parse('no match') }.to raise_error(Walrat::ParseError)
  end
end
