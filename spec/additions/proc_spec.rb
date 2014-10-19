# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'proc additions' do
  it 'responds to "to_parseable", "parse" and "memoizing_parse"' do
    proc = lambda { |string, options| 'foo' }.to_parseable
    proc.parse('bar').should == 'foo'
    proc.memoizing_parse('bar').should == 'foo'
  end
end
