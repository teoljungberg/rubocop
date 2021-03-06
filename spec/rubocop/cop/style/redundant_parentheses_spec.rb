# encoding: utf-8
# frozen_string_literal: true

require 'spec_helper'

describe RuboCop::Cop::Style::RedundantParentheses do
  subject(:cop) { described_class.new }

  shared_examples 'redundant' do |expr, correct, type, highlight = nil|
    it "registers an offense for parentheses around #{type}" do
      inspect_source(cop, expr)
      expect(cop.messages)
        .to eq(["Don't use parentheses around #{type}."])
      expect(cop.highlights).to eq([highlight || expr])
    end

    it 'auto-corrects' do
      expect(autocorrect_source(cop, expr)).to eq correct
    end
  end

  shared_examples 'plausible' do |expr|
    it 'accepts parentheses when arguments are unparenthesized' do
      inspect_source(cop, expr)
      expect(cop.offenses).to be_empty
    end
  end

  shared_examples 'keyword with return value' do |keyword|
    it_behaves_like 'redundant', "(#{keyword})", keyword, 'a keyword'
    it_behaves_like 'redundant', "(#{keyword}())", "#{keyword}()", 'a keyword'
    it_behaves_like 'redundant', "(#{keyword}(1))", "#{keyword}(1)", 'a keyword'
    it_behaves_like 'plausible', "(#{keyword} 1, 2)"
  end

  shared_examples 'keyword with arguments' do |keyword|
    it_behaves_like 'redundant', "(#{keyword})", keyword, 'a keyword'
    it_behaves_like 'redundant', "(#{keyword}())", "#{keyword}()", 'a keyword'
    it_behaves_like 'redundant', "(#{keyword}(1, 2))", "#{keyword}(1, 2)",
                    'a keyword'
    it_behaves_like 'plausible', "(#{keyword} 1, 2)"
  end

  it_behaves_like 'redundant', '("x")', '"x"', 'a literal'
  it_behaves_like 'redundant', '("#{x}")', '"#{x}"', 'a literal'
  it_behaves_like 'redundant', '(:x)', ':x', 'a literal'
  it_behaves_like 'redundant', '(:"#{x}")', ':"#{x}"', 'a literal'
  it_behaves_like 'redundant', '(1)', '1', 'a literal'
  it_behaves_like 'redundant', '(1.2)', '1.2', 'a literal'
  it_behaves_like 'redundant', '({})', '{}', 'a literal'
  it_behaves_like 'redundant', '([])', '[]', 'a literal'
  it_behaves_like 'redundant', '(nil)', 'nil', 'a literal'
  it_behaves_like 'redundant', '(true)', 'true', 'a literal'
  it_behaves_like 'redundant', '(false)', 'false', 'a literal'
  it_behaves_like 'redundant', '(/regexp/)', '/regexp/', 'a literal'
  if RUBY_VERSION >= '2.1'
    it_behaves_like 'redundant', '(1i)', '1i', 'a literal'
    it_behaves_like 'redundant', '(1r)', '1r', 'a literal'
  end

  it_behaves_like 'redundant', '(__FILE__)', '__FILE__', 'a keyword'
  it_behaves_like 'redundant', '(__LINE__)', '__LINE__', 'a keyword'
  it_behaves_like 'redundant', '(__ENCODING__)', '__ENCODING__', 'a keyword'
  it_behaves_like 'redundant', '(redo)', 'redo', 'a keyword'
  it_behaves_like 'redundant', '(retry)', 'retry', 'a keyword'
  it_behaves_like 'redundant', '(self)', 'self', 'a keyword'

  it_behaves_like 'keyword with return value', 'break'
  it_behaves_like 'keyword with return value', 'next'
  it_behaves_like 'keyword with return value', 'return'

  it_behaves_like 'keyword with arguments', 'super'
  it_behaves_like 'keyword with arguments', 'yield'

  it_behaves_like 'redundant', '(defined?(:A))', 'defined?(:A)', 'a keyword'
  it_behaves_like 'plausible', '(defined? :A)'

  it_behaves_like 'plausible', '(alias a b)'
  it_behaves_like 'plausible', '(not 1)'
  it_behaves_like 'plausible', '(a until b)'
  it_behaves_like 'plausible', '(a while b)'

  it_behaves_like 'redundant', 'x = 1; (x)', 'x = 1; x', 'a variable', '(x)'
  it_behaves_like 'redundant', '(@x)', '@x', 'a variable'
  it_behaves_like 'redundant', '(@@x)', '@@x', 'a variable'
  it_behaves_like 'redundant', '($x)', '$x', 'a variable'

  it_behaves_like 'redundant', '(X)', 'X', 'a constant'

  it_behaves_like 'redundant', '(x)', 'x', 'a method call'
  it_behaves_like 'redundant', '(x(1, 2))', 'x(1, 2)', 'a method call'
  it_behaves_like 'redundant', '("x".to_sym)', '"x".to_sym', 'a method call'
  it_behaves_like 'redundant', '(x[:y])', 'x[:y]', 'a method call'

  it 'accepts parentheses around a method call with unparenthesized ' \
     'arguments' do
    inspect_source(cop, '(a 1, 2) && (1 + 1)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses inside an irange' do
    inspect_source(cop, '(a)..(b)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses inside an erange' do
    inspect_source(cop, '(a)...(b)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses around an irange' do
    inspect_source(cop, '(a..b)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses around an erange' do
    inspect_source(cop, '(a...b)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses around operator keywords' do
    inspect_source(cop, '(1 and 2) and (3 or 4)')
    expect(cop.offenses).to be_empty
  end

  it 'registers an offense when there is space around the parentheses' do
    inspect_source(cop, 'if x; y else (1) end')
    expect(cop.offenses.size).to eq 1
  end

  it 'accepts parentheses when they touch the preceding keyword' do
    inspect_source(cop, 'if x; y else(1) end')
    expect(cop.offenses).to be_empty
  end

  it 'accepts parentheses when they touch the following keyword' do
    inspect_source(cop, 'if x; y else (1)end')
    expect(cop.offenses).to be_empty
  end
end
