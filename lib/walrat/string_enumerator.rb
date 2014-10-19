# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'strscan'
require 'walrat'

module Walrat
  # Unicode-aware (UTF-8) string enumerator.
  # For Unicode support $KCODE must be set to 'U' (UTF-8).
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

    # This method will only work as expected if $KCODE is set to 'U' (UTF-8).
    def next
      @last     = @current
      @current  = @scanner.scan(/./m) # must use multiline mode or "." won't match newlines
    end
  end # class StringEnumerator
end # module Walrus
