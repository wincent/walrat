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

require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Walrat::Grammar do
  describe '::rules' do
    it 'complains if either parameter is nil' do
      expect do
        class AxeGrammar < Walrat::Grammar
          rule nil, 'expression'
        end
      end.to raise_error(ArgumentError, /nil symbol/)

      expect do
        class BoneGrammar < Walrat::Grammar
          rule :my_rule, nil
        end
      end.to raise_error(ArgumentError, /nil parseable/)

      expect do
        class CatGrammar < Walrat::Grammar
          rule nil, nil
        end
      end.to raise_error(ArgumentError, /nil/)
    end

    it 'complains if an attempt is made to define a rule a second time' do
      expect do
        class DogGrammar < Walrat::Grammar
          rule :my_rule, 'foo'
          rule :my_rule, 'bar'
        end
      end.to raise_error(ArgumentError, /already defined/)
    end
  end

  describe 'defining productions in a grammar' do
    it '"node" method should complain if new class name is nil' do
      expect do
        class NodeComplainingGrammar < Walrat::Grammar
          node nil
        end
      end.to raise_error(ArgumentError, /nil new_class_name/)
    end

    it 'should be able to define a simple Node subclass using the "node" function' do
      class NodeGrammar1 < Walrat::Grammar
        node      :my_node_subclass
        node      :my_subclass_of_a_subclass, :my_node_subclass
      end

      NodeGrammar1::MyNodeSubclass.superclass.should == Walrat::Node
      NodeGrammar1::MySubclassOfASubclass.superclass.should == NodeGrammar1::MyNodeSubclass
    end

    it 'should complain if an attempt is made to create the same production class twice' do
      expect do
        class HowToGetControlOfJavaAwayFromSun < Walrat::Grammar
          rule        :foo, 'foo'
          node        :foo
          production  :foo
          production  :foo
        end
      end.to raise_error(ArgumentError, /production already defined/)
    end

    it 'should complain if an attempt is made to create a production for a rule that does not exist yet' do
      expect do
        class GettingControlOfJavaAwayFromSun < Walrat::Grammar
          node        :foo
          production  :foo
        end
      end.to raise_error(ArgumentError, /non-existent rule/)
    end
  end

  describe 'parsing using a grammar' do
    it 'should complain if asked to parse a nil string' do
      class BobGrammar < Walrat::Grammar; end
      expect do
        BobGrammar.new.parse(nil)
      end.to raise_error(ArgumentError, /nil string/)
    end

    it 'should complain if trying to parse without first defining a start symbol' do
      class RoyalGrammar < Walrat::Grammar; end
      expect do
        RoyalGrammar.new.parse('foo')
      end.to raise_error(RuntimeError, /starting symbol not defined/)
    end

    it 'should parse starting with the start symbol' do
      class AliceGrammar < Walrat::Grammar
        rule            :expr, /\w+/
        starting_symbol :expr
      end

      grammar = AliceGrammar.new
      grammar.parse('foo').should == 'foo'
      lambda { grammar.parse('') }.should raise_error(Walrat::ParseError)
    end

    it 'should complain if reference is made to an undefined symbol' do
      class RoyGrammar < Walrat::Grammar
        starting_symbol :expr # :expr is not defined
      end

      expect do
        RoyGrammar.new.parse('foo')
      end.should raise_error(/no rule for key/)
    end

    it 'should be able to parse using a simple grammar (one rule)' do
      class SimpleGrammar < Walrat::Grammar
        starting_symbol :foo
        rule            :foo, 'foo!'
      end

      grammar = SimpleGrammar.new
      grammar.parse('foo!').should == 'foo!'
      lambda { grammar.parse('---') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to parse using a simple grammar (two rules)' do
      class AlmostAsSimpleGrammar < Walrat::Grammar
        starting_symbol :foo
        rule            :foo, 'foo!' | :bar
        rule            :bar, /bar/
      end

      grammar = AlmostAsSimpleGrammar.new
      grammar.parse('foo!').should == 'foo!'
      grammar.parse('bar').should == 'bar'
      lambda { grammar.parse('---') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to parse using a simple grammar (three rules)' do
      # a basic version written using intermediary parslets
      # (really two parslets and one rule)
      class MacGrammar < Walrat::Grammar
        starting_symbol :comment

        # parslets
        comment_marker  = '##'
        comment_body    = /.+/

        # rules
        rule            :comment,         comment_marker & comment_body.optional
      end

      grammar = MacGrammar.new
      grammar.parse('## hello!').should == ['##', ' hello!']
      grammar.parse('##').should == '##'
      lambda { grammar.parse('foobar') }.should raise_error(Walrat::ParseError)

      # the same grammar rewritten without intermediary parslets
      # (three rules, no standalone parslets)
      class MacAltGrammar < Walrat::Grammar
        starting_symbol :comment
        rule            :comment,         :comment_marker & :comment_body.optional
        rule            :comment_marker,  '##'
        rule            :comment_body,    /.+/
      end

      grammar = MacAltGrammar.new
      grammar.parse('## hello!').should == ['##', ' hello!']
      grammar.parse('##').should == '##'
      lambda { grammar.parse('foobar') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to parse using recursive rules (nested parentheses)' do
      # basic example
      class NestedGrammar < Walrat::Grammar
        starting_symbol :bracket_expression
        rule            :left_bracket,        '('
        rule            :right_bracket,       ')'
        rule            :bracket_content,     (/[^()]+/ | :bracket_expression).zero_or_more
        rule            :bracket_expression,  :left_bracket & :bracket_content.optional & :right_bracket
      end

      grammar = NestedGrammar.new
      grammar.parse('()').should == ['(', ')']
      grammar.parse('(content)').should == ['(', 'content', ')']
      grammar.parse('(content (and more content))').should == ['(', ['content ', ['(', 'and more content', ')']], ')']
      lambda { grammar.parse('(') }.should raise_error(Walrat::ParseError)

      # same example but automatically skipping the delimiting braces for clearer output
      class NestedSkippingGrammar < Walrat::Grammar
        starting_symbol :bracket_expression
        rule            :bracket_expression,  '('.skip & (/[^()]+/ | :bracket_expression).zero_or_more  & ')'.skip
      end

      grammar = NestedSkippingGrammar.new
      grammar.parse('()').should == []
      grammar.parse('(content)').should == 'content'
      grammar.parse('(content (and more content))').should == ['content ', 'and more content']
      grammar.parse('(content (and more content)(and more))').should == ['content ', 'and more content', 'and more']
      grammar.parse('(content (and more content)(and more)(more still))').should == ['content ', 'and more content', 'and more', 'more still']
      grammar.parse('(content (and more content)(and more(more still)))').should == ['content ', 'and more content', ['and more', 'more still']]
      lambda { grammar.parse('(') }.should raise_error(Walrat::ParseError)

      # note that this confusing (possible even misleading) nesting goes away if you use a proper AST
      class NestedBracketsWithAST < Walrat::Grammar
        starting_symbol :bracket_expression
        rule            :text_expression,     /[^()]+/
        rule            :bracket_expression,
                        '('.skip &
                        (:text_expression | :bracket_expression).zero_or_more  &
                        ')'.skip
        node            :bracket_expression
        production      :bracket_expression, :children
      end

      # simple tests
      grammar = NestedBracketsWithAST.new
      grammar.parse('()').children.should == []
      grammar.parse('(content)').children.to_s.should == 'content'

      # nested test: two expressions at the first level, one of them nested
      results = grammar.parse('(content (and more content))')
      results.children[0].should == 'content '
      results.children[1].children.to_s.should == 'and more content'

      # nested test: three expressions at first level, two of them nested
      results = grammar.parse('(content (and more content)(and more))')#.should == ['content ', 'and more content', 'and more']
      results.children[0].should == 'content '
      results.children[1].children.should == 'and more content'
      results.children[2].children.should == 'and more'

      # nested test: four expressions at the first level, three of them nested
      results = grammar.parse('(content (and more content)(and more)(more still))')
      results.children[0].should == 'content '
      results.children[1].children.should == 'and more content'
      results.children[2].children.should == 'and more'
      results.children[3].children.should == 'more still'

      # nested test: three expressions at the first level, one nested and another not only nested but containing another level of nesting
      results = grammar.parse('(content (and more content)(and more(more still)))')
      results.children[0].should == 'content '
      results.children[1].children.should == 'and more content'
      results.children[2].children[0].should == 'and more'
      results.children[2].children[1].children.should == 'more still'

      # bad input case
      lambda { grammar.parse('(') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to parse using recursive rules (nested comments)' do
      class NestedCommentsGrammar < Walrat::Grammar
        starting_symbol :comment
        rule            :comment_start,       '/*'
        rule            :comment_end,         '*/'
        rule            :comment_content,     (:comment | /\/+/ | ('*' & '/'.not!) | /[^*\/]+/).zero_or_more
        rule            :comment,             '/*' & :comment_content.optional & '*/'
      end

      grammar = NestedCommentsGrammar.new
      grammar.parse('/**/').should == ['/*', '*/']
      grammar.parse('/*comment*/').should == ['/*', 'comment', '*/']
      grammar.parse('/* comment /* nested */*/').should == ['/*', [' comment ', ['/*', ' nested ', '*/']], '*/']
      lambda { grammar.parse('/*') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to write a grammar that produces an AST for a simple language that supports addition and assignment' do
      class SimpleASTLanguage < Walrat::Grammar
        starting_symbol :expression

        # terminal tokens
        rule            :identifier,      /[a-zA-Z_][a-zA-Z0-9_]*/
        node            :identifier
        production      :identifier
        rule            :integer_literal, /[0-9]+/
        node            :integer_literal
        production      :integer_literal

        # expressions
        rule            :expression,      :assignment_expression | :addition_expression | :identifier | :integer_literal
        node            :expression
        rule            :assignment_expression, :identifier & '='.skip & :expression
        node            :assignment_expression, :expression
        production      :assignment_expression, :target, :value
        rule            :addition_expression,   (:identifier | :integer_literal) & '+'.skip & :expression
        node            :addition_expression, :expression
        production      :addition_expression, :summee, :summor
      end

      grammar = SimpleASTLanguage.new
      results = grammar.parse('hello')
      results.should be_kind_of(SimpleASTLanguage::Identifier)
      results.lexeme.should == 'hello'

      results = grammar.parse('1234')
      results.should be_kind_of(SimpleASTLanguage::IntegerLiteral)
      results.lexeme.should == '1234'

      results = grammar.parse('foo=bar')
      results.should be_kind_of(SimpleASTLanguage::Expression)
      results.should be_kind_of(SimpleASTLanguage::AssignmentExpression)
      results.target.should be_kind_of(SimpleASTLanguage::Identifier)
      results.target.lexeme.should == 'foo'
      results.value.should be_kind_of(SimpleASTLanguage::Identifier)
      results.value.lexeme.should == 'bar'

      results = grammar.parse('baz+123')
      results.should be_kind_of(SimpleASTLanguage::Expression)
      results.should be_kind_of(SimpleASTLanguage::AdditionExpression)
      results.summee.should be_kind_of(SimpleASTLanguage::Identifier)
      results.summee.lexeme.should == 'baz'
      results.summor.should be_kind_of(SimpleASTLanguage::IntegerLiteral)
      results.summor.lexeme.should == '123'

      results = grammar.parse('foo=abc+123')
      results.should be_kind_of(SimpleASTLanguage::Expression)
      results.should be_kind_of(SimpleASTLanguage::AssignmentExpression)
      results.target.should be_kind_of(SimpleASTLanguage::Identifier)
      results.target.lexeme.should == 'foo'
      results.value.should be_kind_of(SimpleASTLanguage::AdditionExpression)
      results.value.summee.should be_kind_of(SimpleASTLanguage::Identifier)
      results.value.summee.lexeme.should == 'abc'
      results.value.summor.should be_kind_of(SimpleASTLanguage::IntegerLiteral)
      results.value.summor.lexeme.should == '123'

      results = grammar.parse('a+b+2')
      results.should be_kind_of(SimpleASTLanguage::Expression)
      results.should be_kind_of(SimpleASTLanguage::AdditionExpression)
      results.summee.should be_kind_of(SimpleASTLanguage::Identifier)
      results.summee.lexeme.should == 'a'
      results.summor.should be_kind_of(SimpleASTLanguage::AdditionExpression)
      results.summor.summee.should be_kind_of(SimpleASTLanguage::Identifier)
      results.summor.summee.lexeme.should == 'b'
      results.summor.summor.should be_kind_of(SimpleASTLanguage::IntegerLiteral)
      results.summor.summor.lexeme.should == '2'
    end

    it 'should be able to write a grammar that complains if all the input is not consumed' do
      class ComplainingGrammar < Walrat::Grammar
        starting_symbol :translation_unit
        rule            :translation_unit,  :word_list & :end_of_string.and? | :end_of_string
        rule            :end_of_string,     /\z/
        rule            :whitespace,        /\s+/
        rule            :word,              /[a-z]+/
        rule            :word_list,         :word >> (:whitespace.skip & :word).zero_or_more
      end

      grammar = ComplainingGrammar.new
      grammar.parse('').should == ''
      grammar.parse('foo').should == 'foo'
      grammar.parse('foo bar').should == ['foo', 'bar']
      lambda { grammar.parse('...') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse('foo...') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse('foo bar...') }.should raise_error(Walrat::ParseError)
    end

    it 'should be able to define a default parslet for intertoken skipping' do
      # simple example
      class SkippingGrammar < Walrat::Grammar
        starting_symbol :translation_unit
        skipping        :whitespace_and_newlines
        rule            :whitespace_and_newlines, /[\s\n\r]+/
        rule            :translation_unit,        :word_list & :end_of_string.and? | :end_of_string
        rule            :end_of_string,           /\z/
        rule            :word_list,               :word.zero_or_more
        rule            :word,                    /[a-z0-9_]+/
      end

      # not sure if I can justify the difference in behaviour here compared with the previous grammar
      # if I catch these throws at the grammar level I can return nil
      # but note that the previous grammar returns an empty array, which to_s is just ""
      grammar = SkippingGrammar.new
      lambda { grammar.parse('') }.should throw_symbol(:AndPredicateSuccess)

      grammar.parse('foo').should == 'foo'
      grammar.parse('foo bar').should == ['foo', 'bar']       # intervening whitespace
      grammar.parse('foo bar     ').should == ['foo', 'bar']  # trailing whitespace
      grammar.parse('     foo bar').should == ['foo', 'bar']  # leading whitespace

      # additional example, this time involving the ">>" pseudo-operator
      class SkippingAndMergingGrammar < Walrat::Grammar
        starting_symbol :translation_unit
        skipping        :whitespace_and_newlines
        rule            :whitespace_and_newlines, /[\s\n\r]+/
        rule            :translation_unit,        :word_list & :end_of_string.and? | :end_of_string
        rule            :end_of_string,           /\z/
        rule            :word_list,               :word >> (','.skip & :word).zero_or_more
        rule            :word,                    /[a-z0-9_]+/
      end

      # one word
      grammar = SkippingAndMergingGrammar.new
      grammar.parse('foo').should == 'foo'

      # two words
      grammar.parse('foo,bar').should == ['foo', 'bar']         # no whitespace
      grammar.parse('foo, bar').should == ['foo', 'bar']        # whitespace after
      grammar.parse('foo ,bar').should == ['foo', 'bar']        # whitespace before
      grammar.parse('foo , bar').should == ['foo', 'bar']       # whitespace before and after
      grammar.parse('foo , bar     ').should == ['foo', 'bar']  # trailing and embedded whitespace
      grammar.parse('     foo , bar').should == ['foo', 'bar']  # leading and embedded whitespace

      # three or four words
      grammar.parse('foo , bar, baz').should == ['foo', 'bar', 'baz']
      grammar.parse(' foo , bar, baz ,bin').should == ['foo', 'bar', 'baz', 'bin']
    end

    it 'should complain if trying to set default skipping parslet more than once' do
      expect do
        class SetSkipperTwice < Walrat::Grammar
          skipping :first   # fine
          skipping :again   # should raise here
        end
      end.should raise_error(/default skipping parslet already set/)
    end

    it 'should complain if passed nil' do
      expect do
        class PassNilToSkipping < Walrat::Grammar
          skipping nil
        end
      end.should raise_error(ArgumentError, /nil rule_or_parslet/)
    end

    it 'should be able to override default skipping parslet on a per-rule basis' do
      # the example grammar parses word lists and number lists
      class OverrideDefaultSkippingParslet < Walrat::Grammar
        starting_symbol :translation_unit
        skipping        :whitespace_and_newlines
        rule            :whitespace_and_newlines, /\s+/       # any whitespace including newlines
        rule            :whitespace,              /[ \t\v]+/  # literally only spaces, tabs, not newlines etc
        rule            :translation_unit,        :component.one_or_more & :end_of_string.and? | :end_of_string
        rule            :end_of_string,           /\z/
        rule            :component,               :word_list | :number_list
        rule            :word_list,               :word.one_or_more
        rule            :word,                    /[a-z]+/
        rule            :number,                  /[0-9]+/

        # the interesting bit: we override the skipping rule for number lists
        rule            :number_list,             :number.one_or_more
        skipping        :number_list,             :whitespace # only whitespace, no newlines
      end

      # words in word lists can be separated by whitespace or newlines
      grammar = OverrideDefaultSkippingParslet.new
      grammar.parse('hello world').should ==  ['hello', 'world']
      grammar.parse("hello\nworld").should == ['hello', 'world']
      grammar.parse("hello world\nworld hello").should == ['hello', 'world', 'world', 'hello']

      # numbers in number lists may be separated only by whitespace, not newlines
      grammar.parse('123 456').should == ['123', '456']
      grammar.parse("123\n456").should == ['123', '456'] # this succeeds because parser treats them as two separate number lists
      grammar.parse("123 456\n456 123").should == [['123', '456'], ['456', '123']]

      # intermixing word lists and number lists
      grammar.parse("bar\n123").should == ['bar', '123']
      grammar.parse("123\n456\nbar").should == ['123', '456', 'bar']

      # these were buggy at one point: "123\n456" was getting mashed into "123456" due to misguided use of String#delete! to delete first newline
      grammar.parse("\n123\n456").should == ['123', '456']
      grammar.parse("bar\n123\n456").should == ['bar', '123', '456']
      grammar.parse("baz bar\n123\n456").should == [['baz', 'bar'], '123', '456']
      grammar.parse("hello world\nfoo\n123 456 baz bar\n123\n456").should == [['hello', 'world', 'foo'], ['123', '456'], ['baz', 'bar'], '123', '456']
    end

    it 'should complain if trying to override the default for the same rule twice' do
      expect do
        class OverrideSameRuleTwice < Walrat::Grammar
          rule      :the_rule, 'foo'
          skipping  :the_rule, :the_override  # fine
          skipping  :the_rule, :the_override  # should raise
        end
      end.to raise_error(ArgumentError, /skipping override already set for rule/)
    end

    it "should complain if trying to set an override for a rule that hasn't been defined yet" do
      expect do
        class OverrideUndefinedRule < Walrat::Grammar
          skipping :non_existent_rule, :the_override
        end
      end.to raise_error(ArgumentError, /non-existent rule/)
    end

    it 'use of the "skipping" directive should play nicely with predicates' do
      # example 1: word + predicate
      class NicePlayer < Walrat::Grammar
        starting_symbol :foo
        skipping        :whitespace
        rule            :whitespace,                /[ \t\v]+/
        rule            :foo,                       'hello' & 'world'.and?
      end

      grammar = NicePlayer.new
      grammar.parse('hello world').should == 'hello'
      grammar.parse('hello      world').should == 'hello'
      grammar.parse('helloworld').should == 'hello'
      lambda { grammar.parse('hello') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse('hello buddy') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse("hello\nbuddy") }.should raise_error(Walrat::ParseError)

      # example 2: word + predicate + other word
      class NicePlayer2 < Walrat::Grammar
        starting_symbol :foo
        skipping        :whitespace
        rule            :whitespace,                /[ \t\v]+/
        rule            :foo,                       /hel../ & 'world'.and? & /\w+/
      end

      grammar = NicePlayer2.new
      grammar.parse('hello world').should == ['hello', 'world']
      grammar.parse('hello      world').should == ['hello', 'world']
      grammar.parse('helloworld').should == ['hello', 'world']
      lambda { grammar.parse('hello') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse('hello buddy') }.should raise_error(Walrat::ParseError)
      lambda { grammar.parse("hello\nbuddy") }.should raise_error(Walrat::ParseError)
    end
  end
end
