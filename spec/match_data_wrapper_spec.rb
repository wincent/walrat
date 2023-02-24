# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::MatchDataWrapper do
  before do
    'hello agent' =~ /(\w+)(\s+)(\w+)/
    @match        = Walrat::MatchDataWrapper.new($~)
  end

  it 'raises if initialized with nil' do
    expect do
      Walrat::MatchDataWrapper.new nil
    end.to raise_error(ArgumentError, /nil data/)
  end

  specify 'stored match data persists after multiple matches are executed' do
    original      = @match.match_data     # store original value
    'foo'         =~ /foo/                # clobber $~
    expect(@match.match_data).to eq(original)  # confirm stored value still intact
  end

  specify 'comparisons with Strings work without having to call "to_s"' do
    expect(@match).to         eq('hello agent')  # normal order
    expect('hello agent').to  eq(@match)         # reverse order
    expect(@match).not_to     eq('foobar')       # inverse test sense (not equal)
    expect('foobar').not_to   eq(@match)         # reverse order
  end
end
