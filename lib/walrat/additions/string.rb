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

# Additions to String class for Unicode support.
# Parslet combining methods.
# Convenience methods (to_parseable).
# Conversion utility methods.
class String
  alias old_range []

  def jlength
    chars.to_a.length
  end

  # NOTE: this is a totally Walrat-specific implementation that is
  # unlikely to be of use anywhere else. It is used in only 1 place
  # in the codebase, and works around the fact that the MatchData
  # made available by the index method gets clobbered by the
  # "chars.to_a" call. The same thing happens for alternative
  # methods of counting the chars, such as using jlength or a manual
  # scan.
  #
  # One workaround is for the caller to re-perform the index call just
  # to get the MatchData again, but that is inefficient. So here we
  # just do the addition before returning the result to the caller.
  def jindex_plus_length arg
    if i = index(arg)
      $~[0].length + unpack('C*')[0...i].pack('C*').chars.to_a.length
    end
  end

  # Unlike the normal rindex method, the MatchData in $~ set by the inner
  # rindex call gets clobbered (by the "chars.to_a" call) and is not visible to
  # the caller of this method.
  def jrindex arg, offset = Walrat::NoParameterMarker.instance
    if offset == Walrat::NoParameterMarker.instance
      i = rindex arg
    else
      i = rindex arg, offset
    end
    i ? unpack('C*')[0...i].pack('C*').chars.to_a.length : nil
  end

  # multi-byte friendly [] implementation
  def [](range, other = Walrat::NoParameterMarker.instance)
    if other == Walrat::NoParameterMarker.instance
      if range.kind_of? Range
        chars.to_a[range].join
      else
        old_range range
      end
    else
      old_range range, other
    end
  end

  # Returns a character-level enumerator for the receiver.
  def enumerator
    Walrat::StringEnumerator.new self
  end

  # Rationale: it's ok to add "&" and "|" methods to string because they don't
  # exist yet (they're not overrides).
  include Walrat::ParsletCombining

  # Returns a StringParslet based on the receiver
  def to_parseable
    Walrat::StringParslet.new self
  end

  # Converts the receiver of the form "foo_bar" to "FooBar". Specifically, the
  # receiver is split into pieces delimited by underscores, each component is
  # then converted to captial case (the first letter is capitalized and the
  # remaining letters are lowercased) and finally the components are joined.
  def to_class_name
    self.split('_').collect { |component| component.capitalize}.join
  end
end # class String
