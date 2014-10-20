# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe 'proc additions' do
  it 'responds to "to_parseable", "parse" and "memoizing_parse"' do
    proc = lambda { |string, options| 'foo' }.to_parseable
    expect(proc.parse('bar')).to eq('foo')
    expect(proc.memoizing_parse('bar')).to eq('foo')
  end
end
