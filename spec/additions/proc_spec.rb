# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe 'proc additions' do
  it 'responds to "to_parseable", "parse" and "memoizing_parse"' do
    fn = lambda { |string, options| 'foo' }.to_parseable
    expect(fn.parse('bar')).to eq('foo')
    expect(fn.memoizing_parse('bar')).to eq('foo')
  end
end
