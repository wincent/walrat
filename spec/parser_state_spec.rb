# encoding: utf-8
# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParserState do
  before do
    @base_string = 'this is the string to be parsed'
    @state = Walrat::ParserState.new @base_string
  end

  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::ParserState.new nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'before parsing has started "remainder" should equal the entire string' do
    expect(@state.remainder).to eq(@base_string)
  end

  it 'before parsing has started "remainder" should equal the entire string (when string is an empty string)' do
    expect(Walrat::ParserState.new('').remainder).to eq('')
  end

  it 'before parsing has started "results" should be empty' do
    expect(@state.results).to be_empty
  end

  it '"parsed" should complain if passed nil' do
    expect { @state.parsed(nil) }.to raise_error(ArgumentError)
  end

  it '"skipped" should complain if passed nil' do
    expect { @state.skipped(nil) }.to raise_error(ArgumentError)
  end

  it '"parsed" should return the remainder of the string' do
    expect(@state.parsed('this is the ')).to  eq('string to be parsed')
    expect(@state.parsed('string ')).to       eq('to be parsed')
    expect(@state.parsed('to be parsed')).to  eq('')
  end

  it '"skipped" should return the remainder of the string' do
    expect(@state.skipped('this is the ')).to eq('string to be parsed')
    expect(@state.skipped('string ')).to      eq('to be parsed')
    expect(@state.skipped('to be parsed')).to eq('')
  end

  it '"results" should return an unwrapped parsed result (for single results)' do
    @state.parsed('this')
    expect(@state.results).to eq('this')
  end

  it 'skipped substrings should not appear in "results"' do
    @state.skipped('this')
    expect(@state.results).to be_empty
  end

  it 'should return an array of the parsed results (for multiple results)' do
    @state.parsed('this ')
    @state.parsed('is ')
    expect(@state.results).to eq(['this ', 'is '])
  end

  it 'should work when the entire string is consumed in a single operation (using "parsed")' do
    expect(@state.parsed(@base_string)).to eq('')
    expect(@state.results).to eq(@base_string)
  end

  it 'should work when the entire string is consumed in a single operation (using "skipped")' do
    expect(@state.skipped(@base_string)).to eq('')
    expect(@state.results).to be_empty
  end

  it '"parsed" should complain if passed something that doesn\'t respond to the "line_end" and "column_end" messages' do
    # line_end
    my_mock = double('Mock which does not implement #line_end').as_null_object
    expect(my_mock).to receive(:line_end).and_raise(NoMethodError)
    expect { @state.parsed(my_mock) }.to raise_error(NoMethodError)

    # column_end
    my_mock = double('Mock which does not implement #column_end').as_null_object
    expect(my_mock).to receive(:column_end).and_raise(NoMethodError)
    expect { @state.parsed(my_mock) }.to raise_error(NoMethodError)
  end

  it '"skipped" should complain if passed something that doesn\'t respond to the "line_end" and "column_end" messages' do
    # line_end
    my_mock = double('Mock which does not implement #line_end').as_null_object
    expect(my_mock).to receive(:line_end).and_raise(NoMethodError)
    expect { @state.skipped(my_mock) }.to raise_error(NoMethodError)

    # column_end
    my_mock = double('Mock which does not implement #column_end').as_null_object
    expect(my_mock).to receive(:column_end).and_raise(NoMethodError)
    expect { @state.skipped(my_mock) }.to raise_error(NoMethodError)
  end

  it 'should be able to mix use of "parsed" and "skipped" methods' do
    # first example
    expect(@state.skipped('this is the ')).to  eq('string to be parsed')
    expect(@state.results).to be_empty
    expect(@state.parsed('string ')).to       eq('to be parsed')
    expect(@state.results).to eq('string ')
    expect(@state.skipped('to be parsed')).to  eq('')
    expect(@state.results).to eq('string ')

    # second example (add this test to isolate a bug in another specification)
    state = Walrat::ParserState.new('foo1...')
    expect(state.skipped('foo')).to eq('1...')
    expect(state.remainder).to eq('1...')
    expect(state.results).to be_empty
    expect(state.parsed('1')).to eq('...')
    expect(state.remainder).to eq('...')
    expect(state.results).to eq('1')
  end

  it '"parsed" and "results" methods should work with multi-byte Unicode strings' do
    # basic test
    state = Walrat::ParserState.new('400€, foo')
    expect(state.remainder).to eq('400€, foo')
    expect(state.parsed('40')).to eq('0€, foo')
    expect(state.results).to eq('40')
    expect(state.parsed('0€, ')).to eq('foo')
    expect(state.results).to eq(['40', '0€, '])
    expect(state.parsed('foo')).to eq('')
    expect(state.results).to eq(['40', '0€, ', 'foo'])

    # test with newlines before and after multi-byte chars
    state = Walrat::ParserState.new("400\n or more €...\nfoo")
    expect(state.remainder).to eq("400\n or more €...\nfoo")
    expect(state.parsed("400\n or more")).to eq(" €...\nfoo")
    expect(state.results).to eq("400\n or more")
    expect(state.parsed(' €..')).to eq(".\nfoo")
    expect(state.results).to eq(["400\n or more", ' €..'])
    expect(state.parsed(".\nfoo")).to eq('')
    expect(state.results).to eq(["400\n or more", ' €..', ".\nfoo"])
  end

  it '"skipped" and "results" methods should work with multi-byte Unicode strings' do
    state = Walrat::ParserState.new('400€, foo')
    expect(state.remainder).to eq('400€, foo')
    expect(state.skipped('4')).to eq('00€, foo')
    expect(state.results).to be_empty
    expect(state.parsed('0')).to eq('0€, foo')
    expect(state.results).to eq('0')
    expect(state.skipped('0€, ')).to eq('foo')
    expect(state.results).to eq('0')
    expect(state.parsed('foo')).to eq('')
    expect(state.results).to eq(['0', 'foo'])
  end
end
