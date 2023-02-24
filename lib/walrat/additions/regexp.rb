# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'
require 'walrat/parslet_combining'

class Regexp
  include Walrat::ParsletCombining

  # Returns a RegexpParslet based on the receiver
  def to_parseable
    Walrat::RegexpParslet.new self
  end
end # class Regexp
