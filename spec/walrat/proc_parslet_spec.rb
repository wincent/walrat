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

describe Walrat::ProcParslet do
  before do
    @parslet = lambda do |string, options|
      if string == 'foobar'
        string
      else
        raise Walrat::ParseError.new("expected foobar but got '#{string}'")
      end
    end.to_parseable
  end

  it 'raises an ArgumentError if initialized with nil' do
    expect do
      Walrat::ProcParslet.new nil
    end.to raise_error(ArgumentError, /nil proc/)
  end

  it 'complains if asked to parse nil' do
    expect do
      @parslet.parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 'raises Walrat::ParseError if unable to parse' do
    expect do
      @parslet.parse 'bar'
    end.to raise_error(Walrat::ParseError)
  end

  it 'returns a parsed value if able to parse' do
    @parslet.parse('foobar').should == 'foobar'
  end

  it 'can be compared for equality' do
    # in practice only parslets created with the exact same Proc instance will
    # be eql because Proc returns different hashes for each
    @parslet.should eql(@parslet.clone)
    @parslet.should eql(@parslet.dup)
    @parslet.should_not eql(lambda { nil }.to_parseable)
  end
end
