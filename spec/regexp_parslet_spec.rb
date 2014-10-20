# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

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
    expect { @parslet.parse('an_identifier') }.not_to raise_error
    expect { @parslet.parse('An_Identifier') }.not_to raise_error
    expect { @parslet.parse('AN_IDENTIFIER') }.not_to raise_error
    expect { @parslet.parse('an_identifier1') }.not_to raise_error
    expect { @parslet.parse('An_Identifier1') }.not_to raise_error
    expect { @parslet.parse('AN_IDENTIFIER1') }.not_to raise_error
    expect { @parslet.parse('a') }.not_to raise_error
    expect { @parslet.parse('A') }.not_to raise_error
    expect { @parslet.parse('a9') }.not_to raise_error
    expect { @parslet.parse('A9') }.not_to raise_error
    expect { @parslet.parse('_identifier') }.not_to raise_error
    expect { @parslet.parse('_Identifier') }.not_to raise_error
    expect { @parslet.parse('_IDENTIFIER') }.not_to raise_error
    expect { @parslet.parse('_9Identifier') }.not_to raise_error
    expect { @parslet.parse('_') }.not_to raise_error
  end

  it 'parse should succeed if the input string matches, even if it continues after the match' do
    expect { @parslet.parse('an_identifier, more') }.not_to raise_error
    expect { @parslet.parse('An_Identifier, more') }.not_to raise_error
    expect { @parslet.parse('AN_IDENTIFIER, more') }.not_to raise_error
    expect { @parslet.parse('an_identifier1, more') }.not_to raise_error
    expect { @parslet.parse('An_Identifier1, more') }.not_to raise_error
    expect { @parslet.parse('AN_IDENTIFIER1, more') }.not_to raise_error
    expect { @parslet.parse('a, more') }.not_to raise_error
    expect { @parslet.parse('A, more') }.not_to raise_error
    expect { @parslet.parse('a9, more') }.not_to raise_error
    expect { @parslet.parse('A9, more') }.not_to raise_error
    expect { @parslet.parse('_identifier, more') }.not_to raise_error
    expect { @parslet.parse('_Identifier, more') }.not_to raise_error
    expect { @parslet.parse('_IDENTIFIER, more') }.not_to raise_error
    expect { @parslet.parse('_9Identifier, more') }.not_to raise_error
    expect { @parslet.parse('_, more') }.not_to raise_error
  end

  it 'parse should return a MatchDataWrapper object' do
    expect(@parslet.parse('an_identifier')).to eq('an_identifier')
    expect(@parslet.parse('an_identifier, more')).to eq('an_identifier')
  end

  it 'parse should raise an ArgumentError if passed nil' do
    expect do
      @parslet.parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'parse should raise a ParseError if the input string does not match' do
    expect { @parslet.parse('9') }.to raise_error(Walrat::ParseError)           # a number is not a valid identifier
    expect { @parslet.parse('9fff') }.to raise_error(Walrat::ParseError)        # identifiers must not start with numbers
    expect { @parslet.parse(' identifier') }.to raise_error(Walrat::ParseError) # note the leading whitespace
    expect { @parslet.parse('') }.to raise_error(Walrat::ParseError)            # empty strings can't match
  end

  it 'should be able to compare parslets for equality' do
    expect(/foo/.to_parseable).to eql(/foo/.to_parseable)        # equal
    expect(/foo/.to_parseable).not_to eql(/bar/.to_parseable)    # different
    expect(/foo/.to_parseable).not_to eql(/Foo/.to_parseable)    # differing only in case
    expect(/foo/.to_parseable).not_to eql('foo')                 # totally different classes
  end

  it 'should accurately pack line and column ends into whatever gets returned from "parse"' do
    # single word
    parslet = /.+/m.to_parseable
    result = parslet.parse('hello')
    expect(result.line_end).to eq(0)
    expect(result.column_end).to eq(5)

    # single word with newline at end (UNIX style)
    result = parslet.parse("hello\n")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # single word with newline at end (Classic Mac style)
    result = parslet.parse("hello\r")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # single word with newline at end (Windows style)
    result = parslet.parse("hello\r\n")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # two lines (UNIX style)
    result = parslet.parse("hello\nworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)

    # two lines (Classic Mac style)
    result = parslet.parse("hello\rworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)

    # two lines (Windows style)
    result = parslet.parse("hello\r\nworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)
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
    expect(exception.line_end).to eq(0)
    expect(exception.column_end).to eq(0)

    # fail after 1 character
    begin
      parslet.parse('hfoobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    expect(exception.line_end).to eq(0)
    expect(exception.column_end).to eq(0)

    # fail after end-of-line
    begin
      parslet.parse("hello\r\nfoobar")
    rescue Walrat::ParseError => e
      exception = e
    end
    expect(exception.line_end).to eq(0)
    expect(exception.column_end).to eq(0)
  end
end

describe 'chaining two regexp parslets together' do
  it 'parslets should work in specified order' do
    parslet = Walrat::RegexpParslet.new(/foo.\d/) &
              Walrat::RegexpParslet.new(/bar.\d/)
    expect(parslet.parse('foo_1bar_2')).to eq(['foo_1', 'bar_2'])
  end

  # Parser Expression Grammars match greedily
  it 'parslets should match greedily' do
    # the first parslet should gobble up the entire string, preventing the
    # second parslet from succeeding
    parslet = Walrat::RegexpParslet.new(/foo.+\d/) &
              Walrat::RegexpParslet.new(/bar.+\d/)
    expect { parslet.parse('foo_1bar_2') }.to raise_error(Walrat::ParseError)
  end
end

describe 'alternating two regexp parslets' do
  it 'either parslet should apply to generate a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/)
    expect(parslet.parse('ABC')).to eq('ABC')
    expect(parslet.parse('123')).to eq('123')
  end

  it 'should fail if no parslet generates a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/)
    expect { parslet.parse('abc') }.to raise_error(Walrat::ParseError)
  end

  it 'parslets should be tried in left-to-right order' do
    # in this case the first parslet should win even though the second one is also a valid match
    parslet = Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(..)(.)/)
    match_data = parslet.parse('abc').match_data
    expect(match_data[1]).to eq('a')
    expect(match_data[2]).to eq('bc')

    # here we swap the order; again the first parslet should win
    parslet = Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(.)(..)/)
    match_data = parslet.parse('abc').match_data
    expect(match_data[1]).to eq('ab')
    expect(match_data[2]).to eq('c')
  end
end

describe 'chaining three regexp parslets' do
  it 'parslets should work in specified order' do
    parslet = Walrat::RegexpParslet.new(/foo.\d/) &
              Walrat::RegexpParslet.new(/bar.\d/) &
              Walrat::RegexpParslet.new(/.../)
    expect(parslet.parse('foo_1bar_2ABC')).to eq(['foo_1', 'bar_2', 'ABC'])
  end
end

describe 'alternating three regexp parslets' do
  it 'any parslet should apply to generate a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/) |
              Walrat::RegexpParslet.new(/[a-z]+/)
    expect(parslet.parse('ABC')).to eq('ABC')
    expect(parslet.parse('123')).to eq('123')
    expect(parslet.parse('abc')).to eq('abc')
  end

  it 'should fail if no parslet generates a match' do
    parslet = Walrat::RegexpParslet.new(/\d+/) |
              Walrat::RegexpParslet.new(/[A-Z]+/) |
              Walrat::RegexpParslet.new(/[a-z]+/)
    expect { parslet.parse(':::') }.to raise_error(Walrat::ParseError)
  end

  it 'parslets should be tried in left-to-right order' do
    # in this case the first parslet should win even though the others also produce valid matches
    parslet = Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(...)/)
    match_data = parslet.parse('abc').match_data
    expect(match_data[1]).to eq('a')
    expect(match_data[2]).to eq('bc')

    # here we swap the order; again the first parslet should win
    parslet = Walrat::RegexpParslet.new(/(..)(.)/) |
              Walrat::RegexpParslet.new(/(.)(..)/) |
              Walrat::RegexpParslet.new(/(...)/)
    match_data = parslet.parse('abc').match_data
    expect(match_data[1]).to eq('ab')
    expect(match_data[2]).to eq('c')

    # similar test but this time the first parslet can't win (doesn't match)
    parslet = Walrat::RegexpParslet.new(/foo/) |
              Walrat::RegexpParslet.new(/(...)/) |
              Walrat::RegexpParslet.new(/(.)(..)/)
    match_data = parslet.parse('abc').match_data
    expect(match_data[1]).to eq('abc')
  end
end

describe 'combining chaining and alternation' do
  it 'chaining should having higher precedence than alternation' do
    # equivalent to /foo/ | ( /bar/ & /abc/ )
    parslet = Walrat::RegexpParslet.new(/foo/) |
              Walrat::RegexpParslet.new(/bar/) &
              Walrat::RegexpParslet.new(/abc/)
    expect(parslet.parse('foo')).to eq('foo')                                            # succeed on first choice
    expect(parslet.parse('barabc')).to eq(['bar', 'abc'])                                # succeed on alternate path
    expect { parslet.parse('bar...') }.to raise_error(Walrat::ParseError)       # fail half-way down alternate path
    expect { parslet.parse('lemon') }.to raise_error(Walrat::ParseError)        # fail immediately

    # swap the order, now equivalent to: ( /bar/ & /abc/ ) | /foo/
    parslet = Walrat::RegexpParslet.new(/bar/) &
              Walrat::RegexpParslet.new(/abc/) |
              Walrat::RegexpParslet.new(/foo/)
    expect(parslet.parse('barabc')).to eq(['bar', 'abc'])                                # succeed on first choice
    expect(parslet.parse('foo')).to eq('foo')                                            # succeed on alternate path
    expect { parslet.parse('bar...') }.to raise_error(Walrat::ParseError)       # fail half-way down first path
    expect { parslet.parse('lemon') }.to raise_error(Walrat::ParseError)        # fail immediately
  end

  it 'should be able to override precedence using parentheses' do
    # take first example above and make it ( /foo/ | /bar/ ) & /abc/
    parslet = (Walrat::RegexpParslet.new(/foo/) |
               Walrat::RegexpParslet.new(/bar/)) &
               Walrat::RegexpParslet.new(/abc/)
    expect(parslet.parse('fooabc')).to eq(['foo', 'abc'])                                # first choice
    expect(parslet.parse('barabc')).to eq(['bar', 'abc'])                                # second choice
    expect { parslet.parse('foo...') }.to raise_error(Walrat::ParseError)        # fail in second half
    expect { parslet.parse('bar...') }.to raise_error(Walrat::ParseError)        # another way of failing in second half
    expect { parslet.parse('foo') }.to raise_error(Walrat::ParseError)           # another way of failing in second half
    expect { parslet.parse('bar') }.to raise_error(Walrat::ParseError)           # another way of failing in second half
    expect { parslet.parse('lemon') }.to raise_error(Walrat::ParseError)         # fail immediately
    expect { parslet.parse('abcfoo') }.to raise_error(Walrat::ParseError)        # order matters

    # take second example above and make it /bar/ & ( /abc/ | /foo/ )
    parslet = Walrat::RegexpParslet.new(/bar/) &
      (Walrat::RegexpParslet.new(/abc/) | Walrat::RegexpParslet.new(/foo/))
    expect(parslet.parse('barabc')).to eq(['bar', 'abc'])                                # succeed on first choice
    expect(parslet.parse('barfoo')).to eq(['bar', 'foo'])                                # second choice
    expect { parslet.parse('bar...') }.to raise_error(Walrat::ParseError)       # fail in second part
    expect { parslet.parse('bar') }.to raise_error(Walrat::ParseError)          # another way to fail in second part
    expect { parslet.parse('lemon') }.to raise_error(Walrat::ParseError)        # fail immediately
    expect { parslet.parse('abcbar') }.to raise_error(Walrat::ParseError)       # order matters
  end

  it 'should be able to include long runs of sequences' do
    # A & B & C & D | E
    parslet = Walrat::RegexpParslet.new(/a/) &
              Walrat::RegexpParslet.new(/b/) &
              Walrat::RegexpParslet.new(/c/) &
              Walrat::RegexpParslet.new(/d/) |
              Walrat::RegexpParslet.new(/e/)
    expect(parslet.parse('abcd')).to eq(['a', 'b', 'c', 'd'])
    expect(parslet.parse('e')).to eq('e')
    expect { parslet.parse('f') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to include long runs of options' do
    # A | B | C | D & E
    parslet = Walrat::RegexpParslet.new(/a/) |
              Walrat::RegexpParslet.new(/b/) |
              Walrat::RegexpParslet.new(/c/) |
              Walrat::RegexpParslet.new(/d/) &
              Walrat::RegexpParslet.new(/e/)
    expect(parslet.parse('a')).to eq('a')
    expect(parslet.parse('b')).to eq('b')
    expect(parslet.parse('c')).to eq('c')
    expect(parslet.parse('de')).to eq(['d', 'e'])
    expect { parslet.parse('f') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to alternate repeatedly between sequences and choices' do
    # A & B | C & D | E
    parslet = Walrat::RegexpParslet.new(/a/) &
              Walrat::RegexpParslet.new(/b/) |
              Walrat::RegexpParslet.new(/c/) &
              Walrat::RegexpParslet.new(/d/) |
              Walrat::RegexpParslet.new(/e/)
    expect(parslet.parse('ab')).to eq(['a', 'b'])
    expect(parslet.parse('cd')).to eq(['c', 'd'])
    expect(parslet.parse('e')).to eq('e')
    expect { parslet.parse('f') }.to raise_error(Walrat::ParseError)
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
    expect(parslet.parse('abc')).to eq(['a', 'b', 'c'])
    expect(parslet.parse('d')).to eq('d')
    expect(parslet.parse('e')).to eq('e')
    expect(parslet.parse('fgh')).to eq(['f', 'g', 'h'])
    expect { parslet.parse('i') }.to raise_error(Walrat::ParseError)
  end
end
