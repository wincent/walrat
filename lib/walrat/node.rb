# Copyright 2007-2014 Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'walrat'

module Walrat
  # Make subclasses of this for use in Abstract Syntax Trees (ASTs).
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
      initialize_body = "def initialize #{results.map { |symbol| symbol.to_s }.join(', ')}\n"
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
