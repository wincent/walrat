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

describe Walrat::Predicate do
  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::Predicate.new nil
    end.to raise_error(ArgumentError, /nil parseable/)
  end

  it 'complains if sent "parse" message' do
    # Predicate abstract superclass, "parse" is the responsibility of the
    # subclasses
    expect do
      Walrat::Predicate.new('foo').parse 'bar'
    end.to raise_error(NotImplementedError)
  end

  it 'should be able to compare predicates for equality' do
    Walrat::Predicate.new('foo').should eql(Walrat::Predicate.new('foo'))
    Walrat::Predicate.new('foo').should_not eql(Walrat::Predicate.new('bar'))
  end

  it '"and" and "not" predicates should yield different hashes even if initialized with the same "parseable"' do
    parseable = 'foo'.to_parseable
    p1 = Walrat::Predicate.new(parseable)
    p2 = Walrat::AndPredicate.new(parseable)
    p3 = Walrat::NotPredicate.new(parseable)

    p1.hash.should_not == p2.hash
    p2.hash.should_not == p3.hash
    p3.hash.should_not == p1.hash

    p1.should_not eql(p2)
    p2.should_not eql(p3)
    p3.should_not eql(p1)
  end
end
