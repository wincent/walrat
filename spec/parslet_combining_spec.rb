# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe 'using shorthand operators to combine String, Symbol and Regexp parsers' do
  it 'should be able to chain a String and a Regexp together' do
    # try in one order
    sequence = 'foo' & /\d+/
    expect(sequence.parse('foo1000')).to eq(['foo', '1000'])
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError) # first part alone is not enough
    expect { sequence.parse('1000') }.to raise_error(Walrat::ParseError) # neither is second part alone
    expect { sequence.parse('1000foo') }.to raise_error(Walrat::ParseError) # order matters

    # same test but in reverse order
    sequence = /\d+/ & 'foo'
    expect(sequence.parse('1000foo')).to eq(['1000', 'foo'])
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError) # first part alone is not enough
    expect { sequence.parse('1000') }.to raise_error(Walrat::ParseError) # neither is second part alone
    expect { sequence.parse('foo1000') }.to raise_error(Walrat::ParseError) # order matters
  end

  it 'should be able to choose between a String and a Regexp' do
    # try in one order
    sequence = 'foo' | /\d+/
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('100')).to eq('100')
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)

    # same test but in reverse order
    sequence = /\d+/ | 'foo'
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('100')).to eq('100')
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to freely intermix String and Regexp objects when chaining and choosing' do
    sequence = 'foo' & /\d+/ | 'bar' & /[XYZ]{3}/
    expect(sequence.parse('foo123')).to eq(['foo', '123'])
    expect(sequence.parse('barZYX')).to eq(['bar', 'ZYX'])
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('123') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('XYZ') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('barXY') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to specify minimum and maximum repetition using shorthand methods' do
    # optional (same as "?" in regular expressions)
    sequence = 'foo'.optional
    expect(sequence.parse('foo')).to eq('foo')
    expect { sequence.parse('bar') }.to throw_symbol(:ZeroWidthParseSuccess)

    # zero_or_one (same as optional; "?" in regular expressions)
    sequence = 'foo'.zero_or_one
    expect(sequence.parse('foo')).to eq('foo')
    expect { sequence.parse('bar') }.to throw_symbol(:ZeroWidthParseSuccess)

    # zero_or_more (same as "*" in regular expressions)
    sequence = 'foo'.zero_or_more
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('foofoofoobar')).to eq(['foo', 'foo', 'foo'])
    expect { sequence.parse('bar') }.to throw_symbol(:ZeroWidthParseSuccess)

    # one_or_more (same as "+" in regular expressions)
    sequence = 'foo'.one_or_more
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('foofoofoobar')).to eq(['foo', 'foo', 'foo'])
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)

    # repeat (arbitary limits for min, max; same as {min, max} in regular expressions)
    sequence = 'foo'.repeat(3, 5)
    expect(sequence.parse('foofoofoobar')).to eq(['foo', 'foo', 'foo'])
    expect(sequence.parse('foofoofoofoobar')).to eq(['foo', 'foo', 'foo', 'foo'])
    expect(sequence.parse('foofoofoofoofoobar')).to eq(['foo', 'foo', 'foo', 'foo', 'foo'])
    expect(sequence.parse('foofoofoofoofoofoobar')).to eq(['foo', 'foo', 'foo', 'foo', 'foo'])
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foofoo') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to apply repetitions to other combinations wrapped in parentheses' do
    sequence = ('foo' & 'bar').one_or_more
    expect(sequence.parse('foobar')).to eq(['foo', 'bar'])
    expect(sequence.parse('foobarfoobar')).to eq([['foo', 'bar'], ['foo', 'bar']]) # fails: just returns ['foo', 'bar']
  end

  it 'should be able to combine use of repetition shorthand methods with other shorthand methods' do
    # first we test with chaining
    sequence = 'foo'.optional & 'bar' & 'abc'.one_or_more
    expect(sequence.parse('foobarabc')).to eq(['foo', 'bar', 'abc'])
    expect(sequence.parse('foobarabcabc')).to eq(['foo', 'bar', ['abc', 'abc']])
    expect(sequence.parse('barabc')).to eq(['bar', 'abc'])
    expect { sequence.parse('abc') }.to raise_error(Walrat::ParseError)

    # similar test but with alternation
    sequence = 'foo' | 'bar' | 'abc'.one_or_more
    expect(sequence.parse('foobarabc')).to eq('foo')
    expect(sequence.parse('barabc')).to eq('bar')
    expect(sequence.parse('abc')).to eq('abc')
    expect(sequence.parse('abcabc')).to eq(['abc', 'abc'])
    expect { sequence.parse('nothing') }.to raise_error(Walrat::ParseError)

    # test with defective sequence (makes no sense to use "optional" with alternation, will always succeed)
    sequence = 'foo'.optional | 'bar' | 'abc'.one_or_more
    expect(sequence.parse('foobarabc')).to eq('foo')
    expect { sequence.parse('nothing') }.to throw_symbol(:ZeroWidthParseSuccess)
  end

  it 'should be able to chain a "not predicate"' do
    sequence = 'foo' & 'bar'.not!
    expect(sequence.parse('foo')).to eq('foo') # fails with ['foo'] because that's the way ParserState works...
    expect(sequence.parse('foo...')).to eq('foo') # same
    expect { sequence.parse('foobar') }.to raise_error(Walrat::ParseError)
  end

  it 'an isolated "not predicate" should return a zero-width match' do
    sequence = 'foo'.not!
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('bar') }.to throw_symbol(:NotPredicateSuccess)
  end

  it 'two "not predicates" chained together should act like a union' do
    # this means "not followed by 'foo' and not followed by 'bar'"
    sequence = 'foo'.not! & 'bar'.not!
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('abc') }.to throw_symbol(:NotPredicateSuccess)
  end

  it 'should be able to chain an "and predicate"' do
    sequence = 'foo' & 'bar'.and?
    expect(sequence.parse('foobar')).to eq('foo') # same problem, returns ['foo']
    expect { sequence.parse('foo...') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
  end

  it 'an isolated "and predicate" should return a zero-width match' do
    sequence = 'foo'.and?
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foo') }.to throw_symbol(:AndPredicateSuccess)
  end

  it 'should be able to follow an "and predicate" with other parslets or combinations' do
    # this is equivalent to "foo" if followed by "bar", or any three characters
    sequence = 'foo' & 'bar'.and? | /.../
    expect(sequence.parse('foobar')).to eq('foo') # returns ['foo']
    expect(sequence.parse('abc')).to eq('abc')
    expect { sequence.parse('') }.to raise_error(Walrat::ParseError)

    # it makes little sense for the predicate to follows a choice operator so we don't test that
  end

  it 'should be able to follow a "not predicate" with other parslets or combinations' do
    # this is equivalent to "foo" followed by any three characters other than "bar"
    sequence = 'foo' & 'bar'.not! & /.../
    expect(sequence.parse('fooabc')).to eq(['foo', 'abc'])
    expect { sequence.parse('foobar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foo') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to include a "not predicate" when using a repetition operator' do
    # basic example
    sequence = ('foo' & 'bar'.not!).one_or_more
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('foofoobar')).to eq('foo')
    expect(sequence.parse('foofoo')).to eq(['foo', 'foo'])
    expect { sequence.parse('bar') }.to raise_error(Walrat::ParseError)
    expect { sequence.parse('foobar') }.to raise_error(Walrat::ParseError)

    # variation: note that greedy matching alters the behaviour
    sequence = ('foo' & 'bar').one_or_more & 'abc'.not!
    expect(sequence.parse('foobar')).to eq(['foo', 'bar'])
    expect(sequence.parse('foobarfoobar')).to eq([['foo', 'bar'], ['foo', 'bar']])
    expect { sequence.parse('foobarabc') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to use regular expression shortcuts in conjunction with predicates' do
    # match "foo" as long as it's not followed by a digit
    sequence = 'foo' & /\d/.not!
    expect(sequence.parse('foo')).to eq('foo')
    expect(sequence.parse('foobar')).to eq('foo')
    expect { sequence.parse('foo1') }.to raise_error(Walrat::ParseError)

    # match "word" characters as long as they're not followed by whitespace
    sequence = /\w+/ & /\s/.not!
    expect(sequence.parse('foo')).to eq('foo')
    expect { sequence.parse('foo ') }.to raise_error(Walrat::ParseError)
  end
end

describe 'omitting tokens from the output using the "skip" method' do
  it 'should be able to skip quotation marks delimiting a string' do
    sequence = '"'.skip & /[^"]+/ & '"'.skip
    expect(sequence.parse('"hello world"')).to eq('hello world') # note this is returning a ParserState object
  end

  it 'should be able to skip within a repetition expression' do
    sequence = ('foo'.skip & /\d+/).one_or_more
    expect(sequence.parse('foo1...')).to eq('1')
    expect(sequence.parse('foo1foo2...')).to eq(['1', '2']) # only returns 1
    expect(sequence.parse('foo1foo2foo3...')).to eq(['1', '2', '3']) # only returns 1
  end

  it 'should be able to skip commas separating a list' do
    # closer to real-world use: a comma-separated list
    sequence = /\w+/ & (/\s*,\s*/.skip & /\w+/).zero_or_more
    expect(sequence.parse('a')).to eq('a')
    expect(sequence.parse('a, b')).to eq(['a', 'b'])
    expect(sequence.parse('a, b, c')).to eq(['a', ['b', 'c']])
    expect(sequence.parse('a, b, c, d')).to eq(['a', ['b', 'c', 'd']])

    # again, using the ">>" operator
    sequence = /\w+/ >> (/\s*,\s*/.skip & /\w+/).zero_or_more
    expect(sequence.parse('a')).to eq('a')
    expect(sequence.parse('a, b')).to eq(['a', 'b'])
    expect(sequence.parse('a, b, c')).to eq(['a', 'b', 'c'])
    expect(sequence.parse('a, b, c, d')).to eq(['a', 'b', 'c', 'd'])
  end
end

describe 'using the shorthand ">>" pseudo-operator' do
  it 'should be able to chain the operator multiple times' do
    # comma-separated words followed by comma-separated digits
    sequence = /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more >> (/\s*,\s*/.skip & /\d+/).one_or_more
    expect(sequence.parse('a, 1')).to eq(['a', '1'])
    expect(sequence.parse('a, b, 1')).to eq(['a', 'b', '1'])
    expect(sequence.parse('a, 1, 2')).to eq(['a', '1', '2'])
    expect(sequence.parse('a, b, 1, 2')).to eq(['a', 'b', '1', '2'])

    # same, but enclosed in quotes
    sequence = '"'.skip & /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more >> (/\s*,\s*/.skip & /\d+/).one_or_more & '"'.skip
    expect(sequence.parse('"a, 1"')).to eq(['a', '1'])
    expect(sequence.parse('"a, b, 1"')).to eq(['a', 'b', '1'])
    expect(sequence.parse('"a, 1, 2"')).to eq(['a', '1', '2'])
    expect(sequence.parse('"a, b, 1, 2"')).to eq(['a', 'b', '1', '2'])

    # alternative construction of same
    sequence = /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more & /\s*,\s*/.skip & /\d+/ >> (/\s*,\s*/.skip & /\d+/).zero_or_more
    expect(sequence.parse('a, 1')).to eq(['a', '1'])
    expect(sequence.parse('a, b, 1')).to eq(['a', 'b', '1'])
    expect(sequence.parse('a, 1, 2')).to eq(['a', '1', '2'])
    expect(sequence.parse('a, b, 1, 2')).to eq(['a', 'b', '1', '2'])
  end
end
