# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('spec_helper', File.dirname(__FILE__))

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
  it 'parses with memoizing turned on' do
    pending
  end

  it 'parses with memoizing turned off' do
    pending
  end

  specify 'parsing with memoization turned on is faster' do
    pending
  end
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
