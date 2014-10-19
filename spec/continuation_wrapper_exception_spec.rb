# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

describe 'creating a continuation wrapper exception' do
  it 'complains if initialized with nil' do
    expect do
      Walrat::ContinuationWrapperException.new nil
    end.to raise_error(ArgumentError, /nil continuation/)
  end
end
