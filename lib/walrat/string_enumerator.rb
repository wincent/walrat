# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'strscan'
require 'walrat'

module Walrat
  # Unicode-aware (UTF-8) string enumerator.
  class StringEnumerator
    # Returns the char most recently scanned before the last "next" call, or
    # nil if nothing previously scanned.
    attr_reader :last

    def initialize string
      raise ArgumentError, 'nil string' if string.nil?
      @scanner  = StringScanner.new string
      @current  = nil
      @last     = nil
    end

    def next
      @last     = @current
      @current  = @scanner.scan(/./m) # must use multiline mode or "." won't match newlines
    end
  end # class StringEnumerator
end # module Walrus
