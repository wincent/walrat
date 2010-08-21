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
    substring.should == 'foo'
  end

  specify 'the parsed substring is an an empty string in the case of a zero-width parse success at a lower level' do
    begin
      Walrat::ParsletOmission.new('foo'.optional).parse 'bar' # a contrived example
    rescue Walrat::SkippedSubstringException => e
      substring = e.to_s
    end
    substring.should == ''
  end

  it 'can be compared for equality' do
    Walrat::ParsletOmission.new('foo').
      should eql(Walrat::ParsletOmission.new('foo'))
    Walrat::ParsletOmission.new('foo').
      should_not eql(Walrat::ParsletOmission.new('bar'))
  end
end
