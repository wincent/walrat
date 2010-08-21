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

describe Walrat::ParsletSequence do
  before do
    @p1 = 'foo'.to_parseable
    @p2 = 'bar'.to_parseable
  end

  it 'hashes should be the same if initialized with the same parseables' do
    Walrat::ParsletSequence.new(@p1, @p2).hash.
      should == Walrat::ParsletSequence.new(@p1, @p2).hash
    Walrat::ParsletSequence.new(@p1, @p2).
      should eql(Walrat::ParsletSequence.new(@p1, @p2))
  end

  it 'hashes should (ideally) be different if initialized with different parseables' do
    Walrat::ParsletSequence.new(@p1, @p2).hash.
      should_not == Walrat::ParsletSequence.new('baz'.to_parseable, 'abc'.to_parseable).hash
    Walrat::ParsletSequence.new(@p1, @p2).
      should_not eql(Walrat::ParsletSequence.new('baz'.to_parseable, 'abc'.to_parseable))
  end

  it 'hashes should be different compared to other similar classes even if initialized with the same parseables' do
    Walrat::ParsletSequence.new(@p1, @p2).hash.
      should_not == Walrat::ParsletChoice.new(@p1, @p2).hash
    Walrat::ParsletSequence.new(@p1, @p2).
      should_not eql(Walrat::ParsletChoice.new(@p1, @p2))
  end

  it 'should be able to use Parslet Choice instances as keys in a hash' do
    hash = {}
    key1 = Walrat::ParsletSequence.new(@p1, @p2)
    key2 = Walrat::ParsletSequence.new('baz'.to_parseable, 'abc'.to_parseable)
    hash[:key1] = 'foo'
    hash[:key2] = 'bar'
    hash[:key1].should == 'foo'
    hash[:key2].should == 'bar'
  end
end
