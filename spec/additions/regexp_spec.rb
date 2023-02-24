# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

# For more detailed specification of the RegexpParslet behaviour see
# regexp_parslet_spec.rb.
describe 'using shorthand to get RegexpParslets from Regexp instances' do
  context 'chaining two Regexps with the "&" operator' do
    it 'yields a two-element sequence' do
      sequence = /foo/ & /bar/
      expect(sequence.parse('foobar').map { |each| each.to_s }).to eq(['foo', 'bar'])
    end
  end

  context 'chaining three Regexps with the "&" operator' do
    it 'yields a three-element sequence' do
      sequence = /foo/ & /bar/ & /\.\.\./
      expect(sequence.parse('foobar...').map { |each| each.to_s }).to eq(['foo', 'bar', '...'])
    end
  end

  context 'alternating two Regexps with the "|" operator' do
    it 'yields a MatchDataWrapper' do
      sequence = /foo/ | /bar/
      expect(sequence.parse('foobar').to_s).to eq('foo')
      expect(sequence.parse('bar...').to_s).to eq('bar')
      expect do
        sequence.parse('no match')
      end.to raise_error(Walrat::ParseError)
    end
  end
end
