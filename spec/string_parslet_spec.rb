# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::StringParslet do
  before do
    @parslet = Walrat::StringParslet.new('HELLO')
  end

  it 'should raise an ArgumentError if initialized with nil' do
    expect { Walrat::StringParslet.new(nil) }.to raise_error(ArgumentError)
  end

  it 'parse should succeed if the input string matches' do
    expect { @parslet.parse('HELLO') }.not_to raise_error
  end

  it 'parse should succeed if the input string matches, even if it continues after the match' do
    expect { @parslet.parse('HELLO...') }.not_to raise_error
  end

  it 'parse should return parsed string' do
    expect(@parslet.parse('HELLO')).to eq('HELLO')
    expect(@parslet.parse('HELLO...')).to eq('HELLO')
  end

  it 'parse should raise an ArgumentError if passed nil' do
    expect { @parslet.parse(nil) }.to raise_error(ArgumentError)
  end

  it 'parse should raise a ParseError if the input string does not match' do
    expect { @parslet.parse('GOODBYE') }.to raise_error(Walrat::ParseError)        # total mismatch
    expect { @parslet.parse('GOODBYE, HELLO') }.to raise_error(Walrat::ParseError) # eventually would match, but too late
    expect { @parslet.parse('HELL...') }.to raise_error(Walrat::ParseError)        # starts well, but fails
    expect { @parslet.parse(' HELLO') }.to raise_error(Walrat::ParseError)         # note the leading whitespace
    expect { @parslet.parse('') }.to raise_error(Walrat::ParseError)               # empty strings can't match
  end

  it 'parse exceptions should include a detailed error message' do
    # TODO: catch the raised exception and compare the message
    expect { @parslet.parse('HELL...') }.to raise_error(Walrat::ParseError)
    expect { @parslet.parse('HELL') }.to raise_error(Walrat::ParseError)
  end

  it 'should be able to compare string parslets for equality' do
    expect('foo'.to_parseable).to eql('foo'.to_parseable)           # equal
    expect('foo'.to_parseable).not_to eql('bar'.to_parseable)       # different
    expect('foo'.to_parseable).not_to eql('Foo'.to_parseable)       # differing only in case
    expect('foo'.to_parseable).not_to eql(/foo/)                    # totally different classes
  end

  it 'should accurately pack line and column ends into whatever is returned by "parse"' do
    # single word
    parslet = 'hello'.to_parseable
    result = parslet.parse('hello')
    expect(result.line_end).to eq(0)
    expect(result.column_end).to eq(5)

    # single word with newline at end (UNIX style)
    parslet = "hello\n".to_parseable
    result = parslet.parse("hello\n")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # single word with newline at end (Classic Mac style)
    parslet = "hello\r".to_parseable
    result = parslet.parse("hello\r")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # single word with newline at end (Windows style)
    parslet = "hello\r\n".to_parseable
    result = parslet.parse("hello\r\n")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(0)

    # two lines (UNIX style)
    parslet = "hello\nworld".to_parseable
    result = parslet.parse("hello\nworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)

    # two lines (Classic Mac style)
    parslet = "hello\rworld".to_parseable
    result = parslet.parse("hello\rworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)

    # two lines (Windows style)
    parslet = "hello\r\nworld".to_parseable
    result = parslet.parse("hello\r\nworld")
    expect(result.line_end).to eq(1)
    expect(result.column_end).to eq(5)
  end

  it 'line and column end should reflect last succesfully scanned position prior to failure' do
    # fail right at start
    parslet = "hello\r\nworld".to_parseable
    begin
      parslet.parse('foobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    expect(exception.line_end).to eq(0)
    expect(exception.column_end).to eq(0)

    # fail after 1 character
    begin
      parslet.parse('hfoobar')
    rescue Walrat::ParseError => e
      exception = e
    end
    expect(exception.line_end).to eq(0)
    expect(exception.column_end).to eq(1)

    # fail after end-of-line
    begin
      parslet.parse("hello\r\nfoobar")
    rescue Walrat::ParseError => e
      exception = e
    end
    expect(exception.line_end).to eq(1)
    expect(exception.column_end).to eq(0)
  end
end
