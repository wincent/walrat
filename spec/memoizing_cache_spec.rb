# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::MemoizingCache::NoValueForKey do
  it 'is a singleton' do
    expect do
      Walrat::MemoizingCache::NoValueForKey.new
    end.to raise_error(NoMethodError, /private method/)

    expect(Walrat::MemoizingCache::NoValueForKey.instance.object_id).
      to eq(Walrat::MemoizingCache::NoValueForKey.instance.object_id)
  end

  it 'should be able to use NoValueForKey as the default value for a hash' do
    hash = Hash.new Walrat::MemoizingCache::NoValueForKey.instance
    expect(hash.default).to eq(Walrat::MemoizingCache::NoValueForKey.instance)
    expect(hash[:foo]).to eq(Walrat::MemoizingCache::NoValueForKey.instance)
    hash[:foo] = 'bar'
    expect(hash[:foo]).to eq('bar')
    expect(hash[:bar]).to eq(Walrat::MemoizingCache::NoValueForKey.instance)
  end
end

describe Walrat::MemoizingCache do
  it 'parses with memoizing turned on'
  it 'parses with memoizing turned off'
  it 'parses faster with memoization turned on'
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
    expect(grammar.parse('foo')).to eq('foo')
  end

  it 'retries after short-circuiting if valid continuation point' do
    class MuchMoreRealisticExample < Walrat::Grammar
      starting_symbol :a
      rule            :a, :a & :b | :b
      rule            :b, 'foo'
    end

    # note the right associativity
    grammar = MuchMoreRealisticExample.new
    expect(grammar.parse('foo')).to eq('foo')
    expect(grammar.parse('foofoo')).to eq(['foo', 'foo'])
    expect(grammar.parse('foofoofoo')).to eq([['foo', 'foo'], 'foo'])
    expect(grammar.parse('foofoofoofoo')).to eq([[['foo', 'foo'], 'foo'], 'foo'])
    expect(grammar.parse('foofoofoofoofoo')).to eq([[[['foo', 'foo'], 'foo'], 'foo'], 'foo'])
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
