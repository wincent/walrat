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

require 'walrat'

module Walrat
  class RegexpParslet < Parslet
    attr_reader :hash

    def initialize regexp
      raise ArgumentError, 'nil regexp' if regexp.nil?
      self.expected_regexp = /\A#{regexp}/ # for efficiency, anchor all regexps
    end

    def parse string, options = {}
      raise ArgumentError, 'nil string' if string.nil?
      if string =~ @expected_regexp
        wrapper = MatchDataWrapper.new $~
        match   = $~[0]

        if (line_count = match.scan(/\r\n|\r|\n/).length) != 0        # count number of newlines in match
          column_end    = match.jlength - match.jrindex(/\r|\n/) - 1  # calculate characters on last line
        else                                                          # no newlines in match
          column_end    = match.jlength + (options[:column_start] || 0)
        end

        wrapper.start       = [options[:line_start], options[:column_start]]
        wrapper.end         = [wrapper.line_start + line_count, column_end]
        wrapper.source_text = match.to_s.clone
        wrapper
      else
        raise ParseError.new('non-matching characters "%s" while parsing regular expression "%s"' % [string, @expected_regexp.inspect],
                             :line_end    => (options[:line_start] || 0),
                             :column_end  => (options[:column_start] || 0))
      end
    end

    def eql?(other)
      other.instance_of? RegexpParslet and
        other.expected_regexp == @expected_regexp
    end

    def inspect
      '#<%s:0x%x @expected_regexp=%s>' %
        [self.class.to_s, self.object_id, @expected_regexp.inspect]
    end

  protected

    # For equality comparisons.
    attr_reader :expected_regexp

  private

    def expected_regexp=(regexp)
      @expected_regexp = (regexp.clone rescue regexp)
      update_hash
    end

    def update_hash
      # fixed offset to avoid collisions with @parseable objects
      @hash = @expected_regexp.hash + 15
    end
  end # class RegexpParslet
end # module Walrat
