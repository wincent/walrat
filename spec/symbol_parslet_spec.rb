# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::SymbolParslet do
  it 'should raise an ArgumentError if initialized with nil' do
    expect do
      Walrat::SymbolParslet.new nil
    end.to raise_error(ArgumentError, /nil symbol/)
  end

  it 'should be able to compare symbol parslets for equality' do
    expect(:foo.to_parseable).to eql(:foo.to_parseable)           # equal
    expect(:foo.to_parseable).not_to eql(:bar.to_parseable)       # different
    expect(:foo.to_parseable).not_to eql(:Foo.to_parseable)       # differing only in case
    expect(:foo.to_parseable).not_to eql(/foo/)                   # totally different classes
  end
end
