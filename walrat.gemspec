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

require File.expand_path('lib/walrus/version.rb', File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name              = 'walrus'
  s.version           = Walrus::VERSION
  s.author            = 'Wincent Colaiuta'
  s.email             = 'win@wincent.com'
  s.homepage          = 'https://wincent.com/products/walrus'
  s.rubyforge_project = 'walrus'
  s.platform          = Gem::Platform::RUBY
  s.summary           = 'Object-oriented templating system'
  s.description       = <<-ENDDESC
    Walrus is an object-oriented templating system inspired by and similar
    to the Cheetah Python-powered template engine. It includes a Parser
    Expression Grammar (PEG) parser generator capable of generating an
    integrated lexer, "packrat" parser, and Abstract Syntax Tree (AST)
    builder.
  ENDDESC
  s.require_paths     = ['lib']
  s.has_rdoc          = true

  # TODO: add 'docs' subdirectory, 'README.txt' when they're done
  s.files             = Dir['bin/walrus', 'lib/**/*.rb']
  s.executables       = ['walrus']
  s.add_runtime_dependency('wopen3', '>= 0.1')
  s.add_development_dependency('mkdtemp', '>= 1.0')
  s.add_development_dependency('rspec', '1.3.0')
end
