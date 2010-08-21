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
  # Make subclasses of this for us in Abstract Syntax Trees (ASTs).
  class Node
    include Walrat::LocationTracking

    attr_reader :lexeme

    def initialize lexeme
      @string_value = lexeme.to_s
      @lexeme = lexeme
    end

    def to_s
      @string_value
    end

    # Overrides the default initialize method to accept the defined
    # attributes and sets up an read accessor for each.
    #
    # Raises an error if called directly on Node itself rather than
    # a subclass.
    def self.production *results
      raise 'Node#production called directly on Node' if self == Node

      # set up accessors
      results.each { |result| attr_reader result }

      # set up initializer
      initialize_body = "def initialize #{results.map { |symbol| symbol.to_s}.join(', ')}\n"
      initialize_body << %Q{  @string_value = ""\n}
      results.each do |result|
        initialize_body << "  @#{result} = #{result}\n"
        initialize_body << "  @string_value << #{result}.to_s\n"
      end
      initialize_body << "end\n"
      class_eval initialize_body
    end
  end # class Node
end # module Walrat
