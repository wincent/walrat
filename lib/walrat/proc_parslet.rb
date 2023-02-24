# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  class ProcParslet < Parslet
    attr_reader :hash

    def initialize proc
      raise ArgumentError, 'nil proc' if proc.nil?
      self.expected_proc = proc
    end

    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      @expected_proc.call string, options
    end

    def eql?(other)
      other.instance_of? ProcParslet and other.expected_proc == @expected_proc
    end

  protected

    # For equality comparisons.
    attr_reader :expected_proc

  private

    def expected_proc=(proc)
      @expected_proc = (proc.clone rescue proc)
      update_hash
    end

    def update_hash
      # fixed offset to avoid collisions with @parseable objects
      @hash = @expected_proc.hash + 105
    end
  end # class ProcParslet
end # module Walrat
