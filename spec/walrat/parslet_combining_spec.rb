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

describe 'using shorthand operators to combine String, Symbol and Regexp parsers' do
  it 'should be able to chain a String and a Regexp together' do
    # try in one order
    sequence = 'foo' & /\d+/
    sequence.parse('foo1000').should == ['foo', '1000']
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError) # first part alone is not enough
    lambda { sequence.parse('1000') }.should raise_error(Walrat::ParseError) # neither is second part alone
    lambda { sequence.parse('1000foo') }.should raise_error(Walrat::ParseError) # order matters

    # same test but in reverse order
    sequence = /\d+/ & 'foo'
    sequence.parse('1000foo').should == ['1000', 'foo']
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError) # first part alone is not enough
    lambda { sequence.parse('1000') }.should raise_error(Walrat::ParseError) # neither is second part alone
    lambda { sequence.parse('foo1000') }.should raise_error(Walrat::ParseError) # order matters
  end

  it 'should be able to choose between a String and a Regexp' do
    # try in one order
    sequence = 'foo' | /\d+/
    sequence.parse('foo').should == 'foo'
    sequence.parse('100').should == '100'
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)

    # same test but in reverse order
    sequence = /\d+/ | 'foo'
    sequence.parse('foo').should == 'foo'
    sequence.parse('100').should == '100'
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to freely intermix String and Regexp objects when chaining and choosing' do
    sequence = 'foo' & /\d+/ | 'bar' & /[XYZ]{3}/
    sequence.parse('foo123').should == ['foo', '123']
    sequence.parse('barZYX').should == ['bar', 'ZYX']
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('123') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('XYZ') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('barXY') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to specify minimum and maximum repetition using shorthand methods' do
    # optional (same as "?" in regular expressions)
    sequence = 'foo'.optional
    sequence.parse('foo').should == 'foo'
    lambda { sequence.parse('bar') }.should throw_symbol(:ZeroWidthParseSuccess)

    # zero_or_one (same as optional; "?" in regular expressions)
    sequence = 'foo'.zero_or_one
    sequence.parse('foo').should == 'foo'
    lambda { sequence.parse('bar') }.should throw_symbol(:ZeroWidthParseSuccess)

    # zero_or_more (same as "*" in regular expressions)
    sequence = 'foo'.zero_or_more
    sequence.parse('foo').should == 'foo'
    sequence.parse('foofoofoobar').should == ['foo', 'foo', 'foo']
    lambda { sequence.parse('bar') }.should throw_symbol(:ZeroWidthParseSuccess)

    # one_or_more (same as "+" in regular expressions)
    sequence = 'foo'.one_or_more
    sequence.parse('foo').should == 'foo'
    sequence.parse('foofoofoobar').should == ['foo', 'foo', 'foo']
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)

    # repeat (arbitary limits for min, max; same as {min, max} in regular expressions)
    sequence = 'foo'.repeat(3, 5)
    sequence.parse('foofoofoobar').should == ['foo', 'foo', 'foo']
    sequence.parse('foofoofoofoobar').should == ['foo', 'foo', 'foo', 'foo']
    sequence.parse('foofoofoofoofoobar').should == ['foo', 'foo', 'foo', 'foo', 'foo']
    sequence.parse('foofoofoofoofoofoobar').should == ['foo', 'foo', 'foo', 'foo', 'foo']
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foofoo') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to apply repetitions to other combinations wrapped in parentheses' do
    sequence = ('foo' & 'bar').one_or_more
    sequence.parse('foobar').should == ['foo', 'bar']
    sequence.parse('foobarfoobar').should == [['foo', 'bar'], ['foo', 'bar']] # fails: just returns ['foo', 'bar']
  end

  it 'should be able to combine use of repetition shorthand methods with other shorthand methods' do
    # first we test with chaining
    sequence = 'foo'.optional & 'bar' & 'abc'.one_or_more
    sequence.parse('foobarabc').should == ['foo', 'bar', 'abc']
    sequence.parse('foobarabcabc').should == ['foo', 'bar', ['abc', 'abc']]
    sequence.parse('barabc').should == ['bar', 'abc']
    lambda { sequence.parse('abc') }.should raise_error(Walrat::ParseError)

    # similar test but with alternation
    sequence = 'foo' | 'bar' | 'abc'.one_or_more
    sequence.parse('foobarabc').should == 'foo'
    sequence.parse('barabc').should == 'bar'
    sequence.parse('abc').should == 'abc'
    sequence.parse('abcabc').should == ['abc', 'abc']
    lambda { sequence.parse('nothing') }.should raise_error(Walrat::ParseError)

    # test with defective sequence (makes no sense to use "optional" with alternation, will always succeed)
    sequence = 'foo'.optional | 'bar' | 'abc'.one_or_more
    sequence.parse('foobarabc').should == 'foo'
    lambda { sequence.parse('nothing') }.should throw_symbol(:ZeroWidthParseSuccess)
  end

  it 'should be able to chain a "not predicate"' do
    sequence = 'foo' & 'bar'.not!
    sequence.parse('foo').should == 'foo' # fails with ['foo'] because that's the way ParserState works...
    sequence.parse('foo...').should == 'foo' # same
    lambda { sequence.parse('foobar') }.should raise_error(Walrat::ParseError)
  end

  it 'an isolated "not predicate" should return a zero-width match' do
    sequence = 'foo'.not!
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('bar') }.should throw_symbol(:NotPredicateSuccess)
  end

  it 'two "not predicates" chained together should act like a union' do
    # this means "not followed by 'foo' and not followed by 'bar'"
    sequence = 'foo'.not! & 'bar'.not!
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('abc') }.should throw_symbol(:NotPredicateSuccess)
  end

  it 'should be able to chain an "and predicate"' do
    sequence = 'foo' & 'bar'.and?
    sequence.parse('foobar').should == 'foo' # same problem, returns ['foo']
    lambda { sequence.parse('foo...') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
  end

  it 'an isolated "and predicate" should return a zero-width match' do
    sequence = 'foo'.and?
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foo') }.should throw_symbol(:AndPredicateSuccess)
  end

  it 'should be able to follow an "and predicate" with other parslets or combinations' do
    # this is equivalent to "foo" if followed by "bar", or any three characters
    sequence = 'foo' & 'bar'.and? | /.../
    sequence.parse('foobar').should == 'foo' # returns ['foo']
    sequence.parse('abc').should == 'abc'
    lambda { sequence.parse('') }.should raise_error(Walrat::ParseError)

    # it makes little sense for the predicate to follows a choice operator so we don't test that
  end

  it 'should be able to follow a "not predicate" with other parslets or combinations' do
    # this is equivalent to "foo" followed by any three characters other than "bar"
    sequence = 'foo' & 'bar'.not! & /.../
    sequence.parse('fooabc').should == ['foo', 'abc']
    lambda { sequence.parse('foobar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foo') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to include a "not predicate" when using a repetition operator' do
    # basic example
    sequence = ('foo' & 'bar'.not!).one_or_more
    sequence.parse('foo').should == 'foo'
    sequence.parse('foofoobar').should == 'foo'
    sequence.parse('foofoo').should == ['foo', 'foo']
    lambda { sequence.parse('bar') }.should raise_error(Walrat::ParseError)
    lambda { sequence.parse('foobar') }.should raise_error(Walrat::ParseError)

    # variation: note that greedy matching alters the behaviour
    sequence = ('foo' & 'bar').one_or_more & 'abc'.not!
    sequence.parse('foobar').should == ['foo', 'bar']
    sequence.parse('foobarfoobar').should == [['foo', 'bar'], ['foo', 'bar']]
    lambda { sequence.parse('foobarabc') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to use regular expression shortcuts in conjunction with predicates' do
    # match "foo" as long as it's not followed by a digit
    sequence = 'foo' & /\d/.not!
    sequence.parse('foo').should == 'foo'
    sequence.parse('foobar').should == 'foo'
    lambda { sequence.parse('foo1') }.should raise_error(Walrat::ParseError)

    # match "word" characters as long as they're not followed by whitespace
    sequence = /\w+/ & /\s/.not!
    sequence.parse('foo').should == 'foo'
    lambda { sequence.parse('foo ') }.should raise_error(Walrat::ParseError)
  end
end

describe 'omitting tokens from the output using the "skip" method' do
  it 'should be able to skip quotation marks delimiting a string' do
    sequence = '"'.skip & /[^"]+/ & '"'.skip
    sequence.parse('"hello world"').should == 'hello world' # note this is returning a ParserState object
  end

  it 'should be able to skip within a repetition expression' do
    sequence = ('foo'.skip & /\d+/).one_or_more
    sequence.parse('foo1...').should == '1'
    sequence.parse('foo1foo2...').should == ['1', '2'] # only returns 1
    sequence.parse('foo1foo2foo3...').should == ['1', '2', '3'] # only returns 1
  end

  it 'should be able to skip commas separating a list' do
    # closer to real-world use: a comma-separated list
    sequence = /\w+/ & (/\s*,\s*/.skip & /\w+/).zero_or_more
    sequence.parse('a').should == 'a'
    sequence.parse('a, b').should == ['a', 'b']
    sequence.parse('a, b, c').should == ['a', ['b', 'c']]
    sequence.parse('a, b, c, d').should == ['a', ['b', 'c', 'd']]

    # again, using the ">>" operator
    sequence = /\w+/ >> (/\s*,\s*/.skip & /\w+/).zero_or_more
    sequence.parse('a').should == 'a'
    sequence.parse('a, b').should == ['a', 'b']
    sequence.parse('a, b, c').should == ['a', 'b', 'c']
    sequence.parse('a, b, c, d').should == ['a', 'b', 'c', 'd']
  end
end

describe 'using the shorthand ">>" pseudo-operator' do
  it 'should be able to chain the operator multiple times' do
    # comma-separated words followed by comma-separated digits
    sequence = /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more >> (/\s*,\s*/.skip & /\d+/).one_or_more
    sequence.parse('a, 1').should == ['a', '1']
    sequence.parse('a, b, 1').should == ['a', 'b', '1']
    sequence.parse('a, 1, 2').should == ['a', '1', '2']
    sequence.parse('a, b, 1, 2').should == ['a', 'b', '1', '2']

    # same, but enclosed in quotes
    sequence = '"'.skip & /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more >> (/\s*,\s*/.skip & /\d+/).one_or_more & '"'.skip
    sequence.parse('"a, 1"').should == ['a', '1']
    sequence.parse('"a, b, 1"').should == ['a', 'b', '1']
    sequence.parse('"a, 1, 2"').should == ['a', '1', '2']
    sequence.parse('"a, b, 1, 2"').should == ['a', 'b', '1', '2']

    # alternative construction of same
    sequence = /[a-zA-Z]+/ >> (/\s*,\s*/.skip & /[a-zA-Z]+/).zero_or_more & /\s*,\s*/.skip & /\d+/ >> (/\s*,\s*/.skip & /\d+/).zero_or_more
    sequence.parse('a, 1').should == ['a', '1']
    sequence.parse('a, b, 1').should == ['a', 'b', '1']
    sequence.parse('a, 1, 2').should == ['a', '1', '2']
    sequence.parse('a, b, 1, 2').should == ['a', 'b', '1', '2']
  end
end
