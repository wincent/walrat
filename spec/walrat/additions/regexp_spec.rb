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

require File.expand_path('../../spec_helper', File.dirname(__FILE__))

# For more detailed specification of the RegexpParslet behaviour see
# regexp_parslet_spec.rb.
describe 'using shorthand to get RegexpParslets from Regexp instances' do
  context 'chaining two Regexps with the "&" operator' do
    it 'yields a two-element sequence' do
      sequence = /foo/ & /bar/
      sequence.parse('foobar').map { |each| each.to_s }.should == ['foo', 'bar']
    end
  end

  context 'chaining three Regexps with the "&" operator' do
    it 'yields a three-element sequence' do
      sequence = /foo/ & /bar/ & /\.\.\./
      sequence.parse('foobar...').map { |each| each.to_s }.should == ['foo', 'bar', '...']
    end
  end

  context 'alternating two Regexps with the "|" operator' do
    it 'yields a MatchDataWrapper' do
      sequence = /foo/ | /bar/
      sequence.parse('foobar').to_s.should == 'foo'
      sequence.parse('bar...').to_s.should == 'bar'
      expect do
        sequence.parse('no match')
      end.to raise_error(Walrat::ParseError)
    end
  end
end
