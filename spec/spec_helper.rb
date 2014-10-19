# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'pathname'
require 'rspec'

module Walrat
  module SpecHelper
    # append local "lib" to LOAD_PATH if not already present
    base    = File.expand_path '../lib', File.dirname(__FILE__)
    LIBDIR  = Pathname.new(base).realpath

    # normalize all paths in the load path
    normalized = $:.map { |path| Pathname.new(path).realpath rescue path }

    $:.unshift(LIBDIR) unless normalized.include?(LIBDIR)
  end # module SpecHelper
end # module Walrat

require 'walrat'
