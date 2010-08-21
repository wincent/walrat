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

describe Walrat::StringParslet do
  before do
    @parslet = Walrat::StringParslet.new('HELLO')
  end

  it 'should raise an ArgumentError if initialized with nil' do
    lambda { Walrat::StringParslet.new(nil) }.should raise_error(ArgumentError)
  end

  it 'parse should succeed if the input string matches' do
    lambda { @parslet.parse('HELLO') }.should_not raise_error
  end

  it 'parse should succeed if the input string matches, even if it continues after the match' do
    lambda { @parslet.parse('HELLO...') }.should_not raise_error
  end

  it 'parse should return parsed string' do
    @parslet.parse('HELLO').should == 'HELLO'
    @parslet.parse('HELLO...').should == 'HELLO'
  end

  it 'parse should raise an ArgumentError if passed nil' do
    lambda { @parslet.parse(nil) }.should raise_error(ArgumentError)
  end

  it 'parse should raise a ParseError if the input string does not match' do
    lambda { @parslet.parse('GOODBYE') }.should raise_error(Walrat::ParseError)        # total mismatch
    lambda { @parslet.parse('GOODBYE, HELLO') }.should raise_error(Walrat::ParseError) # eventually would match, but too late
    lambda { @parslet.parse('HELL...') }.should raise_error(Walrat::ParseError)        # starts well, but fails
    lambda { @parslet.parse(' HELLO') }.should raise_error(Walrat::ParseError)         # note the leading whitespace
    lambda { @parslet.parse('') }.should raise_error(Walrat::ParseError)               # empty strings can't match
  end

  it 'parse exceptions should include a detailed error message' do
    # TODO: catch the raised exception and compare the message
    lambda { @parslet.parse('HELL...') }.should raise_error(Walrat::ParseError)
    lambda { @parslet.parse('HELL') }.should raise_error(Walrat::ParseError)
  end

  it 'should be able to compare string parslets for equality' do
    'foo'.to_parseable.should eql('foo'.to_parseable)           # equal
    'foo'.to_parseable.should_not eql('bar'.to_parseable)       # different
    'foo'.to_parseable.should_not eql('Foo'.to_parseable)       # differing only in case
    'foo'.to_parseable.should_not eql(/foo/)                    # totally different classes
  end

  it 'should accurately pack line and column ends into whatever is returned by "parse"' do
    # single word
    parslet = 'hello'.to_parseable
    result = parslet.parse('hello')
    result.line_end.should == 0
    result.column_end.should == 5

    # single word with newline at end (UNIX style)
    parslet = "hello\n".to_parseable
    result = parslet.parse("hello\n")
    result.line_end.should == 1
    result.column_end.should == 0

    # single word with newline at end (Classic Mac style)
    parslet = "hello\r".to_parseable
    result = parslet.parse("hello\r")
    result.line_end.should == 1
    result.column_end.should == 0

    # single word with newline at end (Windows style)
    parslet = "hello\r\n".to_parseable
    result = parslet.parse("hello\r\n")
    result.line_end.should == 1
    result.column_end.should == 0

    # two lines (UNIX style)
    parslet = "hello\nworld".to_parseable
    result = parslet.parse("hello\nworld")
    result.line_end.should == 1
    result.column_end.should == 5

    # two lines (Classic Mac style)
    parslet = "hello\rworld".to_parseable
    result = parslet.parse("hello\rworld")
    result.line_end.should == 1
    result.column_end.should == 5

    # two lines (Windows style)
    parslet = "hello\r\nworld".to_parseable
    result = parslet.parse("hello\r\nworld")
    result.line_end.should == 1
    result.column_end.should == 5
  end

  it 'line and column end should reflect last succesfully scanned position prior to failure' do
    # fail right at start
    parslet = "hello\r\nworld".to_parseable
    begin
      parslet.parse('foobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 0
    exception.column_end.should == 0

    # fail after 1 character
    begin
      parslet.parse('hfoobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 0
    exception.column_end.should == 1

    # fail after end-of-line
    begin
      parslet.parse("hello\r\nfoobar")
    rescue Walrat::ParseError => e
      exception = e
    end
    exception.line_end.should == 1
    exception.column_end.should == 0
  end
end
