# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'spec_helper'

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

      expect(NodeGrammar1::MyNodeSubclass.superclass).to eq(Walrat::Node)
      expect(NodeGrammar1::MySubclassOfASubclass.superclass).to eq(NodeGrammar1::MyNodeSubclass)
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
      expect(grammar.parse('foo')).to eq('foo')
      expect { grammar.parse('') }.to raise_error(Walrat::ParseError)
    end

    it 'should complain if reference is made to an undefined symbol' do
      class RoyGrammar < Walrat::Grammar
        starting_symbol :expr # :expr is not defined
      end

      expect { RoyGrammar.new.parse('foo') }.to raise_error(/no rule for key/)
    end

    it 'should be able to parse using a simple grammar (one rule)' do
      class SimpleGrammar < Walrat::Grammar
        starting_symbol :foo
        rule            :foo, 'foo!'
      end

      grammar = SimpleGrammar.new
      expect(grammar.parse('foo!')).to eq('foo!')
      expect { grammar.parse('---') }.to raise_error(Walrat::ParseError)
    end

    it 'should be able to parse using a simple grammar (two rules)' do
      class AlmostAsSimpleGrammar < Walrat::Grammar
        starting_symbol :foo
        rule            :foo, 'foo!' | :bar
        rule            :bar, /bar/
      end

      grammar = AlmostAsSimpleGrammar.new
      expect(grammar.parse('foo!')).to eq('foo!')
      expect(grammar.parse('bar')).to eq('bar')
      expect { grammar.parse('---') }.to raise_error(Walrat::ParseError)
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
      expect(grammar.parse('## hello!')).to eq(['##', ' hello!'])
      expect(grammar.parse('##')).to eq('##')
      expect { grammar.parse('foobar') }.to raise_error(Walrat::ParseError)

      # the same grammar rewritten without intermediary parslets
      # (three rules, no standalone parslets)
      class MacAltGrammar < Walrat::Grammar
        starting_symbol :comment
        rule            :comment,         :comment_marker & :comment_body.optional
        rule            :comment_marker,  '##'
        rule            :comment_body,    /.+/
      end

      grammar = MacAltGrammar.new
      expect(grammar.parse('## hello!')).to eq(['##', ' hello!'])
      expect(grammar.parse('##')).to eq('##')
      expect { grammar.parse('foobar') }.to raise_error(Walrat::ParseError)
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
      expect(grammar.parse('()')).to eq(['(', ')'])
      expect(grammar.parse('(content)')).to eq(['(', 'content', ')'])
      expect(grammar.parse('(content (and more content))')).to eq(['(', ['content ', ['(', 'and more content', ')']], ')'])
      expect { grammar.parse('(') }.to raise_error(Walrat::ParseError)

      # same example but automatically skipping the delimiting braces for clearer output
      class NestedSkippingGrammar < Walrat::Grammar
        starting_symbol :bracket_expression
        rule            :bracket_expression,  '('.skip & (/[^()]+/ | :bracket_expression).zero_or_more  & ')'.skip
      end

      grammar = NestedSkippingGrammar.new
      expect(grammar.parse('()')).to eq([])
      expect(grammar.parse('(content)')).to eq('content')
      expect(grammar.parse('(content (and more content))')).to eq(['content ', 'and more content'])
      expect(grammar.parse('(content (and more content)(and more))')).to eq(['content ', 'and more content', 'and more'])
      expect(grammar.parse('(content (and more content)(and more)(more still))')).to eq(['content ', 'and more content', 'and more', 'more still'])
      expect(grammar.parse('(content (and more content)(and more(more still)))')).to eq(['content ', 'and more content', ['and more', 'more still']])
      expect { grammar.parse('(') }.to raise_error(Walrat::ParseError)

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
      expect(grammar.parse('()').children).to eq([])
      expect(grammar.parse('(content)').children.to_s).to eq('content')

      # nested test: two expressions at the first level, one of them nested
      results = grammar.parse('(content (and more content))')
      expect(results.children[0]).to eq('content ')
      expect(results.children[1].children.to_s).to eq('and more content')

      # nested test: three expressions at first level, two of them nested
      results = grammar.parse('(content (and more content)(and more))')#.should == ['content ', 'and more content', 'and more']
      expect(results.children[0]).to eq('content ')
      expect(results.children[1].children).to eq('and more content')
      expect(results.children[2].children).to eq('and more')

      # nested test: four expressions at the first level, three of them nested
      results = grammar.parse('(content (and more content)(and more)(more still))')
      expect(results.children[0]).to eq('content ')
      expect(results.children[1].children).to eq('and more content')
      expect(results.children[2].children).to eq('and more')
      expect(results.children[3].children).to eq('more still')

      # nested test: three expressions at the first level, one nested and another not only nested but containing another level of nesting
      results = grammar.parse('(content (and more content)(and more(more still)))')
      expect(results.children[0]).to eq('content ')
      expect(results.children[1].children).to eq('and more content')
      expect(results.children[2].children[0]).to eq('and more')
      expect(results.children[2].children[1].children).to eq('more still')

      # bad input case
      expect { grammar.parse('(') }.to raise_error(Walrat::ParseError)
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
      expect(grammar.parse('/**/')).to eq(['/*', '*/'])
      expect(grammar.parse('/*comment*/')).to eq(['/*', 'comment', '*/'])
      expect(grammar.parse('/* comment /* nested */*/')).to eq(['/*', [' comment ', ['/*', ' nested ', '*/']], '*/'])
      expect { grammar.parse('/*') }.to raise_error(Walrat::ParseError)
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
      expect(results).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.lexeme).to eq('hello')

      results = grammar.parse('1234')
      expect(results).to be_kind_of(SimpleASTLanguage::IntegerLiteral)
      expect(results.lexeme).to eq('1234')

      results = grammar.parse('foo=bar')
      expect(results).to be_kind_of(SimpleASTLanguage::Expression)
      expect(results).to be_kind_of(SimpleASTLanguage::AssignmentExpression)
      expect(results.target).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.target.lexeme).to eq('foo')
      expect(results.value).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.value.lexeme).to eq('bar')

      results = grammar.parse('baz+123')
      expect(results).to be_kind_of(SimpleASTLanguage::Expression)
      expect(results).to be_kind_of(SimpleASTLanguage::AdditionExpression)
      expect(results.summee).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.summee.lexeme).to eq('baz')
      expect(results.summor).to be_kind_of(SimpleASTLanguage::IntegerLiteral)
      expect(results.summor.lexeme).to eq('123')

      results = grammar.parse('foo=abc+123')
      expect(results).to be_kind_of(SimpleASTLanguage::Expression)
      expect(results).to be_kind_of(SimpleASTLanguage::AssignmentExpression)
      expect(results.target).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.target.lexeme).to eq('foo')
      expect(results.value).to be_kind_of(SimpleASTLanguage::AdditionExpression)
      expect(results.value.summee).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.value.summee.lexeme).to eq('abc')
      expect(results.value.summor).to be_kind_of(SimpleASTLanguage::IntegerLiteral)
      expect(results.value.summor.lexeme).to eq('123')

      results = grammar.parse('a+b+2')
      expect(results).to be_kind_of(SimpleASTLanguage::Expression)
      expect(results).to be_kind_of(SimpleASTLanguage::AdditionExpression)
      expect(results.summee).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.summee.lexeme).to eq('a')
      expect(results.summor).to be_kind_of(SimpleASTLanguage::AdditionExpression)
      expect(results.summor.summee).to be_kind_of(SimpleASTLanguage::Identifier)
      expect(results.summor.summee.lexeme).to eq('b')
      expect(results.summor.summor).to be_kind_of(SimpleASTLanguage::IntegerLiteral)
      expect(results.summor.summor.lexeme).to eq('2')
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
      expect(grammar.parse('')).to eq('')
      expect(grammar.parse('foo')).to eq('foo')
      expect(grammar.parse('foo bar')).to eq(['foo', 'bar'])
      expect { grammar.parse('...') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse('foo...') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse('foo bar...') }.to raise_error(Walrat::ParseError)
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
      expect { grammar.parse('') }.to throw_symbol(:AndPredicateSuccess)

      expect(grammar.parse('foo')).to eq('foo')
      expect(grammar.parse('foo bar')).to eq(['foo', 'bar'])       # intervening whitespace
      expect(grammar.parse('foo bar     ')).to eq(['foo', 'bar'])  # trailing whitespace
      expect(grammar.parse('     foo bar')).to eq(['foo', 'bar'])  # leading whitespace

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
      expect(grammar.parse('foo')).to eq('foo')

      # two words
      expect(grammar.parse('foo,bar')).to eq(['foo', 'bar'])         # no whitespace
      expect(grammar.parse('foo, bar')).to eq(['foo', 'bar'])        # whitespace after
      expect(grammar.parse('foo ,bar')).to eq(['foo', 'bar'])        # whitespace before
      expect(grammar.parse('foo , bar')).to eq(['foo', 'bar'])       # whitespace before and after
      expect(grammar.parse('foo , bar     ')).to eq(['foo', 'bar'])  # trailing and embedded whitespace
      expect(grammar.parse('     foo , bar')).to eq(['foo', 'bar'])  # leading and embedded whitespace

      # three or four words
      expect(grammar.parse('foo , bar, baz')).to eq(['foo', 'bar', 'baz'])
      expect(grammar.parse(' foo , bar, baz ,bin')).to eq(['foo', 'bar', 'baz', 'bin'])
    end

    it 'should complain if trying to set default skipping parslet more than once' do
      expect {
        class SetSkipperTwice < Walrat::Grammar
          skipping :first   # fine
          skipping :again   # should raise here
        end
      }.to raise_error(/default skipping parslet already set/)
    end

    it 'should complain if passed nil' do
      expect {
        class PassNilToSkipping < Walrat::Grammar
          skipping nil
        end
      }.to raise_error(ArgumentError, /nil rule_or_parslet/)
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
      expect(grammar.parse('hello world')).to eq(['hello', 'world'])
      expect(grammar.parse("hello\nworld")).to eq(['hello', 'world'])
      expect(grammar.parse("hello world\nworld hello")).to eq(['hello', 'world', 'world', 'hello'])

      # numbers in number lists may be separated only by whitespace, not newlines
      expect(grammar.parse('123 456')).to eq(['123', '456'])
      expect(grammar.parse("123\n456")).to eq(['123', '456']) # this succeeds because parser treats them as two separate number lists
      expect(grammar.parse("123 456\n456 123")).to eq([['123', '456'], ['456', '123']])

      # intermixing word lists and number lists
      expect(grammar.parse("bar\n123")).to eq(['bar', '123'])
      expect(grammar.parse("123\n456\nbar")).to eq(['123', '456', 'bar'])

      # these were buggy at one point: "123\n456" was getting mashed into "123456" due to misguided use of String#delete! to delete first newline
      expect(grammar.parse("\n123\n456")).to eq(['123', '456'])
      expect(grammar.parse("bar\n123\n456")).to eq(['bar', '123', '456'])
      expect(grammar.parse("baz bar\n123\n456")).to eq([['baz', 'bar'], '123', '456'])
      expect(grammar.parse("hello world\nfoo\n123 456 baz bar\n123\n456")).to eq([['hello', 'world', 'foo'], ['123', '456'], ['baz', 'bar'], '123', '456'])
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
      expect(grammar.parse('hello world')).to eq('hello')
      expect(grammar.parse('hello      world')).to eq('hello')
      expect(grammar.parse('helloworld')).to eq('hello')
      expect { grammar.parse('hello') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse('hello buddy') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse("hello\nbuddy") }.to raise_error(Walrat::ParseError)

      # example 2: word + predicate + other word
      class NicePlayer2 < Walrat::Grammar
        starting_symbol :foo
        skipping        :whitespace
        rule            :whitespace,                /[ \t\v]+/
        rule            :foo,                       /hel../ & 'world'.and? & /\w+/
      end

      grammar = NicePlayer2.new
      expect(grammar.parse('hello world')).to eq(['hello', 'world'])
      expect(grammar.parse('hello      world')).to eq(['hello', 'world'])
      expect(grammar.parse('helloworld')).to eq(['hello', 'world'])
      expect { grammar.parse('hello') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse('hello buddy') }.to raise_error(Walrat::ParseError)
      expect { grammar.parse("hello\nbuddy") }.to raise_error(Walrat::ParseError)
    end
  end
end
