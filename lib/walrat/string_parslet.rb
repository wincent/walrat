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
  class StringParslet < Parslet
    attr_reader :hash

    def initialize string
      raise ArgumentError if string.nil?
      self.expected_string = string
    end

    def parse string, options = {}
      raise ArgumentError if string.nil?
      chars         = StringEnumerator.new string
      parsed        = StringResult.new
      parsed.start  = [options[:line_start], options[:column_start]]
      parsed.end    = parsed.start
      expected_string.each_char do |expected_char|
        actual_char = chars.next
        if actual_char.nil?
          raise ParseError.new('unexpected end-of-string (expected "%s") while parsing "%s"' %
                               [ expected_char, expected_string ],
                               :line_end    => parsed.line_end,
                               :column_end  => parsed.column_end)
        elsif actual_char != expected_char
          raise ParseError.new('unexpected character "%s" (expected "%s") while parsing "%s"' %
                               [ actual_char, expected_char, expected_string],
                               :line_end    => parsed.line_end,
                               :column_end  => parsed.column_end)
        else
          if actual_char == "\r" or
            (actual_char == "\n" and chars.last != "\r")  # catches Mac, Windows and UNIX end-of-line markers
            parsed.column_end = 0
            parsed.line_end   = parsed.line_end + 1
          elsif actual_char != "\n"                     # \n is ignored if it is preceded by an \r (already counted above)
            parsed.column_end = parsed.column_end + 1   # everything else gets counted
          end
          parsed << actual_char
        end
      end
      parsed.source_text = parsed.to_s.clone
      parsed
    end

    def eql?(other)
      other.instance_of? StringParslet and
        other.expected_string == @expected_string
    end

  protected

    # For equality comparisons.
    attr_reader :expected_string

  private

    def expected_string=(string)
      @expected_string = (string.clone rescue string)
      update_hash
    end

    def update_hash
      # fixed offset to avoid collisions with @parseable objects
      @hash = @expected_string.hash + 20
    end
  end # class StringParslet
end # module Walrat
