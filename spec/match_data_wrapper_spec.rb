# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('spec_helper', File.dirname(__FILE__))

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
    @match.match_data.should == original  # confirm stored value still intact
  end

  specify 'comparisons with Strings work without having to call "to_s"' do
    @match.should         == 'hello agent'  # normal order
    'hello agent'.should  == @match         # reverse order
    @match.should_not     == 'foobar'       # inverse test sense (not equal)
    'foobar'.should_not   == @match         # reverse order
  end
end
