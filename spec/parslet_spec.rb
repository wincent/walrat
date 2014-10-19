# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe Walrat::Parslet do
  it 'complains if sent "parse" message' do
    # Parslet is an abstract superclass, "parse" is the responsibility of the
    # subclasses
    expect do
      Walrat::Parslet.new.parse('bar')
    end.to raise_error(NotImplementedError)
  end
end
