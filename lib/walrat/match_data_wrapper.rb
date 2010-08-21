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
  # Simple wrapper for MatchData objects that implements length, to_s and
  # to_str methods.
  #
  # By implementing to_str, MatchDataWrappers can be directly compared with
  # Strings using the == method. The original MatchData instance can be
  # obtained using the match_data accessor. Upon creation a clone of the passed
  # in MatchData object is stored; this means that the $~ global variable can
  # be conveniently wrapped without having to worry that subsequent operations
  # will alter the contents of the variable.
  class MatchDataWrapper
    include Walrat::LocationTracking

    attr_reader :match_data

    # Raises if data is nil.
    def initialize data
      raise ArgumentError, 'nil data' if data.nil?
      self.match_data = data
    end

    # The definition of this method, in conjunction with the == method, allows
    # automatic comparisons with String objects using the == method.
    # This is because in a parser matches essentially are Strings (just like
    # Exceptions and Pathnames); it's just that this class encapsulates a
    # little more information (the match data) for those who want it.
    def to_str
      self.to_s
    end

    # Although this method explicitly allows for MatchDataWrapper to
    # MatchDataWrapper comparisons, note that all such comparisons will return
    # false except for those between instances which were initialized with
    # exactly the same match data instance; this is because the MatchData class
    # itself always returns false when compared with other MatchData instances.
    def ==(other)
      if other.kind_of? MatchDataWrapper
        self.match_data == other.match_data
      elsif other.respond_to? :to_str
        self.to_str == other.to_str
      else
        false
      end
    end

    def to_s
      @match_data[0]
    end

    def jlength
      self.to_s.jlength
    end

  private

    def match_data=(data)
      @match_data = (data.clone rescue data)
    end
  end # class MatchDataWrapper
end # module Walrat
