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

describe Walrat::MemoizingCache::NoValueForKey do
  it 'is a singleton' do
    expect do
      Walrat::MemoizingCache::NoValueForKey.new
    end.to raise_error(NoMethodError, /private method/)

    Walrat::MemoizingCache::NoValueForKey.instance.object_id.
      should == Walrat::MemoizingCache::NoValueForKey.instance.object_id
  end

  it 'should be able to use NoValueForKey as the default value for a hash' do
    hash = Hash.new Walrat::MemoizingCache::NoValueForKey.instance
    hash.default.should == Walrat::MemoizingCache::NoValueForKey.instance
    hash[:foo].should == Walrat::MemoizingCache::NoValueForKey.instance
    hash[:foo] = 'bar'
    hash[:foo].should == 'bar'
    hash[:bar].should == Walrat::MemoizingCache::NoValueForKey.instance
  end
end

describe Walrat::MemoizingCache do
  it 'parses with memoizing turned on'
  it 'parses with memoizing turned off'
  specify 'parsing with memoization turned on is faster'
end

# left-recursion is enabled by code in the memoizer and elsewhere; keep the
# specs here for want of a better place
describe 'working with left-recursive rules' do
  specify 'circular rules should cause a short-circuit' do
    class InfiniteLoop < Walrat::Grammar
      starting_symbol :a
      rule            :a, :a # a bone-headed rule
    end

    grammar = InfiniteLoop.new
    expect do
      grammar.parse('anything')
    end.to raise_error(Walrat::LeftRecursionException)
  end

  specify 'shortcuiting is not be fatal if a valid alternative is present' do
    class AlmostInfinite < Walrat::Grammar
      starting_symbol :a
      rule            :a, :a | :b # slightly less bone-headed
      rule            :b, 'foo'
    end

    grammar = AlmostInfinite.new
    grammar.parse('foo').should == 'foo'
  end

  it 'retries after short-circuiting if valid continuation point' do
    class MuchMoreRealisticExample < Walrat::Grammar
      starting_symbol :a
      rule            :a, :a & :b | :b
      rule            :b, 'foo'
    end

    # note the right associativity
    grammar = MuchMoreRealisticExample.new
    grammar.parse('foo').should == 'foo'
    grammar.parse('foofoo').should == ['foo', 'foo']
    grammar.parse('foofoofoo').should == [['foo', 'foo'], 'foo']
    grammar.parse('foofoofoofoo').should == [[['foo', 'foo'], 'foo'], 'foo']
    grammar.parse('foofoofoofoofoo').should == [[[['foo', 'foo'], 'foo'], 'foo'], 'foo']
  end

  specify 'right associativity should work when building AST nodes' do
    class RightAssociativeAdditionExample < Walrat::Grammar
      starting_symbol :addition_expression
      rule            :term, /\d+/
      rule            :addition_expression,
                      :addition_expression & '+'.skip & :term | :term
      node            :addition_expression
      production      :addition_expression, :left, :right

      # TODO: syntax for expressing alternate production?
    end

    pending
    grammar = RightAssociativeAdditionExample.new
    result = grammar.parse('1+2')
  end
end
