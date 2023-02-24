# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

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
