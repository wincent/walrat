# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

class Proc
  include Walrat::ParsletCombining

  # Returns a ProcParslet based on the receiver
  def to_parseable
    Walrat::ProcParslet.new self
  end
end # class Proc
