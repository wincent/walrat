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

# Ruby 1.9 support
require 'continuation' unless Kernel.respond_to?(:callcc)

module Walrat
  major, minor = RUBY_VERSION.split '.'
  if major == '1' and minor == '8'
    $KCODE  = 'U' # UTF-8 (necessary for Unicode support)
  end

  autoload :AndPredicate,                 'walrat/and_predicate'
  autoload :ArrayResult,                  'walrat/array_result'
  autoload :ContinuationWrapperException, 'walrat/continuation_wrapper_exception'
  autoload :Grammar,                      'walrat/grammar'
  autoload :LeftRecursionException,       'walrat/left_recursion_exception'
  autoload :LocationTracking,             'walrat/location_tracking'
  autoload :MatchDataWrapper,             'walrat/match_data_wrapper'
  autoload :Memoizing,                    'walrat/memoizing'
  autoload :MemoizingCache,               'walrat/memoizing_cache'
  autoload :Node,                         'walrat/node'
  autoload :NoParameterMarker,            'walrat/no_parameter_marker'
  autoload :NotPredicate,                 'walrat/not_predicate'
  autoload :ParseError,                   'walrat/parse_error'
  autoload :ParserState,                  'walrat/parser_state'

  # TODO: move these into subdirectory? directory for predicates also?
  autoload :Parslet,                      'walrat/parslet'
  autoload :ParsletChoice,                'walrat/parslet_choice'
  autoload :ParsletCombination,           'walrat/parslet_combination'
  autoload :ParsletCombining,             'walrat/parslet_combining'
  autoload :ParsletMerge,                 'walrat/parslet_merge'
  autoload :ParsletOmission,              'walrat/parslet_omission'
  autoload :ParsletRepetition,            'walrat/parslet_repetition'
  autoload :ParsletRepetitionDefault,     'walrat/parslet_repetition_default'
  autoload :ParsletSequence,              'walrat/parslet_sequence'
  autoload :Predicate,                    'walrat/predicate'
  autoload :ProcParslet,                  'walrat/proc_parslet'
  autoload :RegexpParslet,                'walrat/regexp_parslet'
  autoload :SkippedSubstringException,    'walrat/skipped_substring_exception'
  autoload :StringEnumerator,             'walrat/string_enumerator'
  autoload :StringParslet,                'walrat/string_parslet'
  autoload :StringResult,                 'walrat/string_result'
  autoload :SymbolParslet,                'walrat/symbol_parslet'
end # module Walrat

require 'walrat/additions/proc'
require 'walrat/additions/regexp'
require 'walrat/additions/string'
require 'walrat/additions/symbol'
