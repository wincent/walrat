# Copyright 2007-2010 Wincent Colaiuta. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require File.expand_path('../spec_helper', File.dirname(__FILE__))

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
