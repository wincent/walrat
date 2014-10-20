# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::ParsletOmission do
  it 'raises if "parseable" argument is nil' do
    expect do
      Walrat::ParsletOmission.new nil
    end.to raise_error(ArgumentError, /nil parseable/)
  end

  it 'complains if passed nil string for parsing' do
    expect do
      Walrat::ParsletOmission.new('foo'.to_parseable).parse nil
    end.to raise_error(ArgumentError, /nil string/)
  end

  it 're-raises parse errors from lower levels' do
    expect do
      Walrat::ParsletOmission.new('foo'.to_parseable).parse 'bar'
    end.to raise_error(Walrat::ParseError)
  end

  it 'indicates parse errors with a SubstringSkippedException' do
    expect do
      Walrat::ParsletOmission.new('foo'.to_parseable).parse 'foo'
    end.to raise_error(Walrat::SkippedSubstringException)
  end

  specify 'the raised SubstringSkippedException includes the parsed substring' do
    begin
      Walrat::ParsletOmission.new('foo'.to_parseable).parse 'foobar'
    rescue Walrat::SkippedSubstringException => e
      substring = e.to_s
    end
    expect(substring).to eq('foo')
  end

  specify 'the parsed substring is an an empty string in the case of a zero-width parse success at a lower level' do
    begin
      Walrat::ParsletOmission.new('foo'.optional).parse 'bar' # a contrived example
    rescue Walrat::SkippedSubstringException => e
      substring = e.to_s
    end
    expect(substring).to eq('')
  end

  it 'can be compared for equality' do
    expect(Walrat::ParsletOmission.new('foo')).
      to eql(Walrat::ParsletOmission.new('foo'))
    expect(Walrat::ParsletOmission.new('foo')).
      not_to eql(Walrat::ParsletOmission.new('bar'))
  end
end
