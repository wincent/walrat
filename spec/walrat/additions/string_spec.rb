# encoding: utf-8
# Copyright 2007-2010 Wincent Colaiuta. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe String do
  describe '#to_class_name' do
    it 'works with require names' do
      'foo_bar'.to_class_name.should == 'FooBar'
    end

    it 'works with a single-letter' do
      'f'.to_class_name.should == 'F'
    end

    it 'works with double-underscores' do
      'foo__bar'.to_class_name.should == 'FooBar'
    end

    it 'works with terminating double-underscores' do
      'foo__'.to_class_name.should == 'Foo'
    end
  end
end

describe 'iterating over a string' do
  # formerly a bug: the StringScanner used under the covers was returning nil
  # (stopping) on hitting a newline
  it 'should be able to iterate over strings containing newlines' do
    chars = []
    "hello\nworld".each_char { |c| chars << c }
    chars.should == ['h', 'e', 'l', 'l', 'o', "\n",
      'w', 'o', 'r', 'l', 'd']
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
    chars.should == ['U', 'n', 'i', 'c', 'o', 'd', 'e', ' ', '€', '!']
  end

  it 'the "chars" method should work with multibyte characters' do
    @string.chars.to_a.should == ['U', 'n', 'i', 'c', 'o', 'd', 'e', ' ', '€', '!']
  end

  it 'should be able to use "enumerator" convenience method to get a string enumerator' do
    enumerator = 'hello€'.enumerator
    enumerator.next.should == 'h'
    enumerator.next.should == 'e'
    enumerator.next.should == 'l'
    enumerator.next.should == 'l'
    enumerator.next.should == 'o'
    enumerator.next.should == '€'
    enumerator.next.should be_nil
  end

  it 'the "jlength" method should correctly report the number of characters in a string' do
    @string.jlength.should  == 10
    "€".jlength.should      == 1  # three bytes long, but one character
  end
end

# For more detailed specification of the StringParslet behaviour see
# string_parslet_spec.rb.
describe 'using shorthand to get StringParslets from String instances' do
  it 'chaining two Strings with the "&" operator should yield a two-element sequence' do
    sequence = 'foo' & 'bar'
    sequence.parse('foobar').should == ['foo', 'bar']
    lambda { sequence.parse('no match') }.should raise_error(Walrat::ParseError)
  end

  it 'chaining three Strings with the "&" operator should yield a three-element sequence' do
    sequence = 'foo' & 'bar' & '...'
    sequence.parse('foobar...').should == ['foo', 'bar', '...']
    lambda { sequence.parse('no match') }.should raise_error(Walrat::ParseError)
  end

  it 'alternating two Strings with the "|" operator should yield a single string' do
    sequence = 'foo' | 'bar'
    sequence.parse('foo').should == 'foo'
    sequence.parse('foobar').should == 'foo'
    sequence.parse('bar').should == 'bar'
    lambda { sequence.parse('no match') }.should raise_error(Walrat::ParseError)
  end
end
