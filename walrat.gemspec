# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require File.expand_path('lib/walrat/version.rb', File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.author                = 'Greg Hurrell'
  s.email                 = 'greg@hurrell.net'
  s.homepage              = 'https://wincent.com/products/walrat'
  s.licenses              = ['BSD-2-Clause']
  s.name                  = 'walrat'
  s.platform              = Gem::Platform::RUBY
  s.require_paths         = ['lib']
  s.required_ruby_version = '>= 3.0'
  s.rubyforge_project     = 'walrus'
  s.summary               = 'Object-oriented templating system'
  s.version               = Walrat::VERSION
  s.description           = <<-DESC
    Walrat is a Parsing Expression Grammar (PEG) parser generator that
    creates integrated lexers, "packrat" parsers, and Abstract Syntax Tree
    (AST) builders.
  DESC

  # TODO: add 'docs' subdirectory, 'README.txt' when they're done
  s.files             = Dir['lib/**/*.rb']
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'yard', '~> 0.5.8'
end
