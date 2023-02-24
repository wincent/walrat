= Walrat =

Walrat is a Parsing Expression Grammar (PEG) parser generator, written in Ruby,
that produces "packrat" (memoizing) parsers capable of lexing, parsing and
building arbitrarily complex Abstract Syntax Trees (ASTs).

Walrat was originally written in 2007 as part of the Walrus object-oriented
templating system. In 2010 it was extracted into a separate gem for easier
reuse in other projects. The Walrus grammar is an excellent example of some of
the more advanced parsing techniques that can be achieved using Walrat,
including:

* dynamic parser generation at runtime via a simple DSL
* standard PEG constructs such as ordered choice, concatenation, repetition
and predicates
* string and regular-expression based "parslets"
* arbitrarily complex proc/lambda based "parslets"
* convenient and customizable inter-token skipping behavior (whitespace
skipping)
* left-recursion
* left-associative and right associative productions
* dynamic AST node synthesis
* addition of custom behavior to AST nodes (such as compilation behavior)
through custom Ruby code
* multiline comments, including nested multiline comments
* "island" parsers for processing "here" documents and include files


== Example ==

    require 'rubygems'
    require 'walrat'
    
    class MySuperGrammar < Walrat::Grammar
      starting_symbol :sequence
      skipping        :whitespace
      rule            :whitespace, /\s+/
      rule            :sequence, :digits & (',' & :digits).zero_or_more
      rule            :digits, /\d+/
    end
    
    grammar = MySuperGrammar.new
    
    begin
      grammar.parse 'hello!'
    rescue Walrat::ParseError => e
      puts "bad input: failed to parse (#{e})"
    end
    
    result = grammar.parse '123, 456, 789'
    puts "good input: parsed (#{result})"

Running this file produces the following output:

    bad input: failed to parse (non-matching characters "hello!" while parsing regular expression "/\A(?-mix:\d+)/")
    good input: parsed (123,456,789)


== System requirements ==

The original release of Walrat (0.1) only supported Ruby 1.8, although it could
work to some degree on other versions.

From the 0.2 release on, Ruby 2.1 is required.

JRuby is not yet officially supported, although many complex grammars (such as
the Walrus grammar) have already been successfully tested.


== Installation ==

    sudo gem install walrat


== Development ==

    $ git clone git://git.wincent.com/walrat.git
    $ cd walrat
    $ bundle install --binstubs
    $ bin/spec spec


== Website ==

The official website can be found at:

  https://wincent.com/products/walrat

The official Git repository can be browsed at:

  http://git.wincent.com/walrat.git

The repository is mirrored hourly to GitHub:

  http://github.com/wincent/walrat


== Author ==

Walrat is written and maintained by Greg Hurrell <greg@hurrell.net>.


== License ==

Copyright 2007-present Greg Hurrell. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
