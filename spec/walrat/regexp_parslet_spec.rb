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

require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Walrat::RegexpParslet do
  before do
    @parslet = Walrat::RegexpParslet.new(/[a-zA-Z_][a-zA-Z0-9_]*/)
  end

  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::RegexpParslet.new nil
    end.to raise_error(ArgumentError, /nil regexp/)
  end

  it 'parse should succeed if the input string matches' do
    lambda { @parslet.parse('an_identifier') }.should_not raise_error
    lambda { @parslet.parse('An_Identifier') }.should_not raise_error
    lambda { @parslet.parse('AN_IDENTIFIER') }.should_not raise_error
    lambda { @parslet.parse('an_identifier1') }.should_not raise_error
    lambda { @parslet.parse('An_Identifier1') }.should_not raise_error
    lambda { @parslet.parse('AN_IDENTIFIER1') }.should_not raise_error
    lambda { @parslet.parse('a') }.should_not raise_error
    lambda { @parslet.parse('A') }.should_not raise_error
    lambda { @parslet.parse('a9') }.should_not raise_error
    lambda { @parslet.parse('A9') }.should_not raise_error
    lambda { @parslet.parse('_identifier') }.should_not raise_error
    lambda { @parslet.parse('_Identifier') }.should_not raise_error
    lambda { @parslet.parse('_IDENTIFIER') }.should_not raise_error
    lambda { @parslet.parse('_9Identifier') }.should_not raise_error
    lambda { @parslet.parse('_') }.should_not raise_error
  end

  it 'parse should succeed if the input string matches, even if it continues after the match' do
    lambda { @parslet.parse('an_identifier, more') }.should_not raise_error
    lambda { @parslet.parse('An_Identifier, more') }.should_not raise_error
    lambda { @parslet.parse('AN_IDENTIFIER, more') }.should_not raise_error
    lambda { @parslet.parse('an_identifier1, more') }.should_not raise_error
    lambda { @parslet.parse('An_Identifier1, more') }.should_not raise_error
    lambda { @parslet.parse('AN_IDENTIFIER1, more') }.should_not raise_error
    lambda { @parslet.parse('a, more') }.should_not raise_error
    lambda { @parslet.parse('A, more') }.should_not raise_error
    lambda { @parslet.parse('a9, more') }.should_not raise_error
    lambda { @parslet.parse('A9, more') }.should_not raise_error
    lambda { @parslet.parse('_identifier, more') }.should_not raise_error
    lambda { @parslet.parse('_Identifier, more') }.should_not raise_error
    lambda { @parslet.parse('_IDENTIFIER, more') }.should_not raise_error
    lambda { @parslet.parse('_9Identifier, more') }.should_not raise_error
    lambda { @parslet.parse('_, more') }.should_not raise_error
  end

  it 'parse should return a MatchDataWrapper object' do
    @parslet.parse('an_identifier').should == 'an_identifier'
    @parslet.parse('an_identifier, more').should == 'an_identifier'
  end

  it 'parse should raise an ArgumentError if passed nil' do
    expect do
      @parslet.parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'parse should raise a ParseError if the input string does not match' do
    lambda { @parslet.parse('9') }.should raise_error(Walrat::ParseError)           # a number is not a valid identifier
    lambda { @parslet.parse('9fff') }.should raise_error(Walrat::ParseError)        # identifiers must not start with numbers
    lambda { @parslet.parse(' identifier') }.should raise_error(Walrat::ParseError) # note the leading whitespace
    lambda { @parslet.parse('') }.should raise_error(Walrat::ParseError)            # empty strings can't match
  end

  it 'should be able to compare parslets for equality' do
    /foo/.to_parseable.should eql(/foo/.to_parseable)        # equal
    /foo/.to_parseable.should_not eql(/bar/.to_parseable)    # different
    /foo/.to_parseable.should_not eql(/Foo/.to_parseable)    # differing only in case
    /foo/.to_parseable.should_not eql('foo')                 # totally different classes
  end

  it 'should accurately pack line and column ends into whatever gets returned from "parse"' do
    # single word
    parslet = /.+/m.to_parseable
    result = parslet.parse('hello')
    result.line_end.should == 0
    result.column_end.should == 5

    # single word with newline at end (UNIX style)
    result = parslet.parse("hello\n")
    result.line_end.should == 1
    result.column_end.should == 0

    # single word with newline at end (Classic Mac style)
    result = parslet.parse("hello\r")
    result.line_end.should == 1
    result.column_end.should == 0

    # single word with newline at end (Windows style)
    result = parslet.parse("hello\r\n")
    result.line_end.should == 1
    result.column_end.should == 0

    # two lines (UNIX style)
    result = parslet.parse("hello\nworld")
    result.line_end.should == 1
    result.column_end.should == 5

    # two lines (Classic Mac style)
    result = parslet.parse("hello\rworld")
    result.line_end.should == 1
    result.column_end.should == 5

    # two lines (Windows style)
    result = parslet.parse("hello\r\nworld")
    result.line_end.should == 1
    result.column_end.should == 5
  end

  # in the case of RegexpParslets, the "last successfully scanned position" is
  # always 0, 0
  it 'line and column end should reflect last succesfully scanned position prior to failure' do
    # fail right at start
    parslet = /hello\r\nworld/.to_parseable
    begin
      parslet.parse('foobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 0
    exception.column_end.should == 0

    # fail after 1 character
    begin
      parslet.parse('hfoobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 0
    exception.column_end.should == 0

    # fail after end-of-line
    begin
      parslet.parse("hello\r\nfoobar")
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 0
    exception.column_end.should == 0
  end
end

describe 'chaining two regexp parslets together' do
  it 'parslets should work in specified order' do
    parslet = Walrat::RegexpParslet.new(/foo.\d/) &
              Walrat::RegexpParslet.new(/bar.\d/)
    parslet.parse('foo_1bar_2').should == ['foo_1', 'bar_2']
  end

  # Parser Expression Grammars match greedily
  it 'parslets should match greedily' do
    # the first parslet should gobble up the entire string, preventing the
    # second parslet from succeeding
    parslet = Walrat::RegexpParslet.new(/foo.+\d/) &
              Walrat::RegexpParslet.new(/bar.+\d/)
    lambda { parslet.parse('foo_1bar_2') }.should raise_error(Walrat::ParseError)
  end
end

describe 'alternating two regexp parslets' do
  it 'either parslet should apply to generate a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/)
    parslet.parse('ABC').should == 'ABC'
    parslet.parse('123').should == '123'
  end

  it 'should fail if no parslet generates a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/)
    lambda { parslet.parse('abc') }.should raise_error(Walrat::ParseError)
  end

  it 'parslets should be tried in left-to-right order' do
    # in this case the first parslet should win even though the second one is also a valid match
    parslet = Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(..)(.)/)
    match_data = parslet.parse('abc').match_data
    match_data[1].should == 'a'
    match_data[2].should == 'bc'

    # here we swap the order; again the first parslet should win
    parslet = Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(.)(..)/)
    match_data = parslet.parse('abc').match_data
    match_data[1].should == 'ab'
    match_data[2].should == 'c'
  end
end

describe 'chaining three regexp parslets' do
  it 'parslets should work in specified order' do
    parslet = Walrat::RegexpParslet.new(/foo.\d/) &
              Walrat::RegexpParslet.new(/bar.\d/) &
              Walrat::RegexpParslet.new(/.../)
    parslet.parse('foo_1bar_2ABC').should == ['foo_1', 'bar_2', 'ABC']
  end
end

describe 'alternating three regexp parslets' do
  it 'any parslet should apply to generate a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/) |
              Walrat::RegexpParslet.new(/[a-z]+/)
    parslet.parse('ABC').should == 'ABC'
    parslet.parse('123').should == '123'
    parslet.parse('abc').should == 'abc'
  end

  it 'should fail if no parslet generates a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/) |
              Walrat::RegexpParslet.new(/[a-z]+/)
    lambda { parslet.parse(':::') }.should raise_error(Walrat::ParseError)
  end

  it 'parslets should be tried in left-to-right order' do
    # in this case the first parslet should win even though the others also produce valid matches
    parslet = Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(...)/)
    match_data = parslet.parse('abc').match_data
    match_data[1].should == 'a'
    match_data[2].should == 'bc'

    # here we swap the order; again the first parslet should win
    parslet = Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(...)/)
    match_data = parslet.parse('abc').match_data
    match_data[1].should == 'ab'
    match_data[2].should == 'c'

    # similar test but this time the first parslet can't win (doesn't match)
    parslet = Walrat::RegexpParslet.new(/foo/) |
              Walrat::RegexpParslet.new(/(...)/) |
              Walrat::RegexpParslet.new(/(.)(..)/)
    match_data = parslet.parse('abc').match_data
    match_data[1].should == 'abc'
  end
end

describe 'combining chaining and alternation' do
  it 'chaining should having higher precedence than alternation' do
    # equivalent to /foo/ | ( /bar/ & /abc/ )
    parslet = Walrat::RegexpParslet.new(/foo/) |
              Walrat::RegexpParslet.new(/bar/) &
              Walrat::RegexpParslet.new(/abc/)
    parslet.parse('foo').should == 'foo'                                            # succeed on first choice
    parslet.parse('barabc').should == ['bar', 'abc']                                # succeed on alternate path
    lambda { parslet.parse('bar...') }.should raise_error(Walrat::ParseError)       # fail half-way down alternate path
    lambda { parslet.parse('lemon') }.should raise_error(Walrat::ParseError)        # fail immediately

    # swap the order, now equivalent to: ( /bar/ & /abc/ ) | /foo/
    parslet = Walrat::RegexpParslet.new(/bar/) &
              Walrat::RegexpParslet.new(/abc/) |
              Walrat::RegexpParslet.new(/foo/)
    parslet.parse('barabc').should == ['bar', 'abc']                                # succeed on first choice
    parslet.parse('foo').should == 'foo'                                            # succeed on alternate path
    lambda { parslet.parse('bar...') }.should raise_error(Walrat::ParseError)       # fail half-way down first path
    lambda { parslet.parse('lemon') }.should raise_error(Walrat::ParseError)        # fail immediately
  end

  it 'should be able to override precedence using parentheses' do
    # take first example above and make it ( /foo/ | /bar/ ) & /abc/
    parslet = (Walrat::RegexpParslet.new(/foo/) |
               Walrat::RegexpParslet.new(/bar/)) &
               Walrat::RegexpParslet.new(/abc/)
    parslet.parse('fooabc').should == ['foo', 'abc']                                # first choice
    parslet.parse('barabc').should == ['bar', 'abc']                                # second choice
    lambda { parslet.parse('foo...') }.should raise_error(Walrat::ParseError)        # fail in second half
    lambda { parslet.parse('bar...') }.should raise_error(Walrat::ParseError)        # another way of failing in second half
    lambda { parslet.parse('foo') }.should raise_error(Walrat::ParseError)           # another way of failing in second half
    lambda { parslet.parse('bar') }.should raise_error(Walrat::ParseError)           # another way of failing in second half
    lambda { parslet.parse('lemon') }.should raise_error(Walrat::ParseError)         # fail immediately
    lambda { parslet.parse('abcfoo') }.should raise_error(Walrat::ParseError)        # order matters

    # take second example above and make it /bar/ & ( /abc/ | /foo/ )
    parslet = Walrat::RegexpParslet.new(/bar/) &
      (Walrat::RegexpParslet.new(/abc/) | Walrat::RegexpParslet.new(/foo/))
    parslet.parse('barabc').should == ['bar', 'abc']                                # succeed on first choice
    parslet.parse('barfoo').should == ['bar', 'foo']                                # second choice
    lambda { parslet.parse('bar...') }.should raise_error(Walrat::ParseError)       # fail in second part
    lambda { parslet.parse('bar') }.should raise_error(Walrat::ParseError)          # another way to fail in second part
    lambda { parslet.parse('lemon') }.should raise_error(Walrat::ParseError)        # fail immediately
    lambda { parslet.parse('abcbar') }.should raise_error(Walrat::ParseError)       # order matters
  end

  it 'should be able to include long runs of sequences' do
    # A & B & C & D | E
    parslet = Walrat::RegexpParslet.new(/a/) &
              Walrat::RegexpParslet.new(/b/) &
              Walrat::RegexpParslet.new(/c/) &
              Walrat::RegexpParslet.new(/d/) |
              Walrat::RegexpParslet.new(/e/)
    parslet.parse('abcd').should == ['a', 'b', 'c', 'd']
    parslet.parse('e').should == 'e'
    lambda { parslet.parse('f') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to include long runs of options' do
    # A | B | C | D & E
    parslet = Walrat::RegexpParslet.new(/a/) |
              Walrat::RegexpParslet.new(/b/) |
              Walrat::RegexpParslet.new(/c/) |
              Walrat::RegexpParslet.new(/d/) &
              Walrat::RegexpParslet.new(/e/)
    parslet.parse('a').should == 'a'
    parslet.parse('b').should == 'b'
    parslet.parse('c').should == 'c'
    parslet.parse('de').should == ['d', 'e']
    lambda { parslet.parse('f') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to alternate repeatedly between sequences and choices' do
    # A & B | C & D | E
    parslet = Walrat::RegexpParslet.new(/a/) &
              Walrat::RegexpParslet.new(/b/) |
              Walrat::RegexpParslet.new(/c/) &
              Walrat::RegexpParslet.new(/d/) |
              Walrat::RegexpParslet.new(/e/)
    parslet.parse('ab').should == ['a', 'b']
    parslet.parse('cd').should == ['c', 'd']
    parslet.parse('e').should == 'e'
    lambda { parslet.parse('f') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to combine long runs with alternation' do
    # A & B & C | D | E | F & G & H
    parslet = Walrat::RegexpParslet.new(/a/) &
              Walrat::RegexpParslet.new(/b/) &
              Walrat::RegexpParslet.new(/c/) |
              Walrat::RegexpParslet.new(/d/) |
              Walrat::RegexpParslet.new(/e/) |
              Walrat::RegexpParslet.new(/f/) &
              Walrat::RegexpParslet.new(/g/) &
              Walrat::RegexpParslet.new(/h/)
    parslet.parse('abc').should == ['a', 'b', 'c']
    parslet.parse('d').should == 'd'
    parslet.parse('e').should == 'e'
    parslet.parse('fgh').should == ['f', 'g', 'h']
    lambda { parslet.parse('i') }.should raise_error(Walrat::ParseError)
  end
end
