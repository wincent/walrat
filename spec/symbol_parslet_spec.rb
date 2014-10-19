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
    :foo.to_parseable.should eql(:foo.to_parseable)           # equal
    :foo.to_parseable.should_not eql(:bar.to_parseable)       # different
    :foo.to_parseable.should_not eql(:Foo.to_parseable)       # differing only in case
    :foo.to_parseable.should_not eql(/foo/)                   # totally different classes
  end
end
