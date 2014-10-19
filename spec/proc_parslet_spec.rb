# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('spec_helper', File.dirname(__FILE__))

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
    @parslet.parse('foobar').should == 'foobar'
  end

  it 'can be compared for equality' do
    # in practice only parslets created with the exact same Proc instance will
    # be eql because Proc returns different hashes for each
    @parslet.should eql(@parslet.clone)
    @parslet.should eql(@parslet.dup)
    @parslet.should_not eql(lambda { nil }.to_parseable)
  end
end
