# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ProcParslet do
  before do
    @parslet = lambda do |string, options|
      if string == 'foobar'
        string
      else
        raise Walrat::ParseError.new("expected foobar but got '#{string}'")
      end
    end.to_parseable
  end

  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::ProcParslet.new nil
    end.to raise_error(ArgumentError, /nil proc/)
  end

  it 'complains if asked to parse nil' do
    expect do
      @parslet.parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'raises Walrat::ParseError if unable to parse' do
    expect do
      @parslet.parse 'bar'
    end.to raise_error(Walrat::ParseError)
  end

  it 'returns a parsed value if able to parse' do
    expect(@parslet.parse('foobar')).to eq('foobar')
  end

  it 'can be compared for equality' do
    # in practice only parslets created with the exact same Proc instance will
    # be eql because Proc returns different hashes for each
    expect(@parslet).to eql(@parslet.clone)
    expect(@parslet).to eql(@parslet.dup)
    expect(@parslet).not_to eql(lambda { nil }.to_parseable)
  end
end
