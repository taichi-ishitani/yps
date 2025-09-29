# frozen_string_literal: true

RSpec.describe YPS do
  def have_position_info(line:, column:, filename: nil)
    have_attributes(position: have_attributes(line:, column:, filename:))
  end

  def match_element(value, line:, column:, filename: nil)
    eq(value).and have_position_info(line:, column:, filename:)
  end

  describe '.safe_load' do
    it 'parses the given YAML and add position information to each parsed elements' do
      yaml = <<~'YAML'
      children:
        - name: Kanta
          age: 8
        - name: Kaede
          age: 3
      YAML
      result = YPS.safe_load(yaml)

      expect(result).to have_position_info(line: 1, column: 1)
      expect(result['children']).to have_position_info(line: 2, column: 3)

      expect(result['children'][0]).to have_position_info(line: 2, column: 5)
      expect(result['children'][0]['name']).to match_element('Kanta', line: 2, column: 11)
      expect(result['children'][0]['age']).to match_element(8, line: 3, column: 10)

      expect(result['children'][1]).to have_position_info(line: 4, column: 5)
      expect(result['children'][1]['name']).to match_element('Kaede', line: 4, column: 11)
      expect(result['children'][1]['age']).to match_element(3, line: 5, column: 10)
    end

    describe 'the permitted_classes option' do
      it 'specifies additonal classed which are allowed to be safe_loaded' do
        yaml = <<~'YAML'
        - 2025-09-28
        - :foo
        YAML

        expect { YPS.safe_load(yaml) }.to raise_error Psych::DisallowedClass

        result = YPS.safe_load(yaml, permitted_classes: [Symbol, Date])
        expect(result[0]).to match_element(Date.new(2025, 9, 28), line: 1, column: 3)
        expect(result[1]).to match_element(:foo, line: 2, column: 3)
      end
    end

    describe 'the permitted_symbols option' do
      let(:yaml) do
        <<~'YAML'
        - :foo
        - :bar
        YAML
      end
      context 'when no symbols are specified' do
        specify 'any symbols can be safe_loaded' do
          result = YPS.safe_load(yaml, permitted_classes: [Symbol])
          expect(result[0]).to match_element(:foo, line: 1, column: 3)
          expect(result[1]).to match_element(:bar, line: 2, column: 3)
        end
      end

      context 'when symbols are specified' do
        specify 'the given symbols can only be safe_loaded' do
          expect { YPS.safe_load(yaml, permitted_classes: [Symbol], permitted_symbols: [:foo]) }
            .to raise_error Psych::DisallowedClass

          result = YPS.safe_load(yaml, permitted_classes: [Symbol], permitted_symbols: [:foo, :bar])
          expect(result[0]).to match_element(:foo, line: 1, column: 3)
          expect(result[1]).to match_element(:bar, line: 2, column: 3)
        end
      end
    end

    describe 'the aliases option' do
      it 'specifies whether or not aliases can be explicitly allowed' do
        yaml = <<~'YAML'
        - &foo_bar
          - foo
          - bar
        - *foo_bar
        YAML

        error_class = RUBY_VERSION >= '3.2.0' && Psych::AliasesNotEnabled || Psych::BadAlias
        expect { YPS.safe_load(yaml) }.to raise_error error_class
        expect { YPS.safe_load(yaml, aliases: false) }.to raise_error error_class

        result = YPS.safe_load(yaml, aliases: true)
        expect(result[0]).to have_position_info(line: 1, column: 3)
        expect(result[0][0]).to match_element('foo', line: 2, column: 5)
        expect(result[0][1]).to match_element('bar', line: 3, column: 5)
        expect(result[1]).to have_position_info(line: 4, column: 3)
        expect(result[1][0]).to match_element('foo', line: 2, column: 5)
        expect(result[1][1]).to match_element('bar', line: 3, column: 5)
      end
    end

    describe 'the filename option' do
      specify 'the file name given by this option will be added to each position info' do
        yaml = <<~'YAML'
        children:
          - name: Kanta
            age: 8
          - name: Kaede
            age: 3
        YAML
        filename = 'test.yaml'
        result = YPS.safe_load(yaml, filename:)

        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result['children']).to have_position_info(line: 2, column: 3, filename:)

        expect(result['children'][0]).to have_position_info(line: 2, column: 5, filename:)
        expect(result['children'][0]['name']).to match_element('Kanta', line: 2, column: 11, filename:)
        expect(result['children'][0]['age']).to match_element(8, line: 3, column: 10, filename:)

        expect(result['children'][1]).to have_position_info(line: 4, column: 5, filename:)
        expect(result['children'][1]['name']).to match_element('Kaede', line: 4, column: 11, filename:)
        expect(result['children'][1]['age']).to match_element(3, line: 5, column: 10, filename:)
      end
    end

    describe 'the fallback option' do
      it 'specifies the return value which will be returned when an empty YAML is given' do
        result = YPS.safe_load('')
        expect(result).to be_nil

        fallback = []
        result = YPS.safe_load('', fallback:)
        expect(result).to equal(fallback)
      end
    end

    describe 'the symbolize_names option' do
      it 'specifies whether or not all mapping keys will be converted into Symbol' do
        yaml = <<~'YAML'
        foo:
          - bar: 0
            baz: 1
          - bar: 2
            baz: 3
        YAML

        result = YPS.safe_load(yaml)
        expect(result).to have_position_info(line: 1, column: 1)
        expect(result['foo']).to have_position_info(line: 2, column: 3)
        expect(result['foo'][0]).to have_position_info(line: 2, column: 5)
        expect(result['foo'][0]['bar']).to match_element(0, line: 2, column: 10)
        expect(result['foo'][0]['baz']).to match_element(1, line: 3, column: 10)
        expect(result['foo'][1]).to have_position_info(line: 4, column: 5)
        expect(result['foo'][1]['bar']).to match_element(2, line: 4, column: 10)
        expect(result['foo'][1]['baz']).to match_element(3, line: 5, column: 10)

        result = YPS.safe_load(yaml, symbolize_names: false)
        expect(result).to have_position_info(line: 1, column: 1)
        expect(result['foo']).to have_position_info(line: 2, column: 3)
        expect(result['foo'][0]).to have_position_info(line: 2, column: 5)
        expect(result['foo'][0]['bar']).to match_element(0, line: 2, column: 10)
        expect(result['foo'][0]['baz']).to match_element(1, line: 3, column: 10)
        expect(result['foo'][1]).to have_position_info(line: 4, column: 5)
        expect(result['foo'][1]['bar']).to match_element(2, line: 4, column: 10)
        expect(result['foo'][1]['baz']).to match_element(3, line: 5, column: 10)

        result = YPS.safe_load(yaml, symbolize_names: true)
        expect(result).to have_position_info(line: 1, column: 1)
        expect(result[:foo]).to have_position_info(line: 2, column: 3)
        expect(result[:foo][0]).to have_position_info(line: 2, column: 5)
        expect(result[:foo][0][:bar]).to match_element(0, line: 2, column: 10)
        expect(result[:foo][0][:baz]).to match_element(1, line: 3, column: 10)
        expect(result[:foo][1]).to have_position_info(line: 4, column: 5)
        expect(result[:foo][1][:bar]).to match_element(2, line: 4, column: 10)
        expect(result[:foo][1][:baz]).to match_element(3, line: 5, column: 10)
      end
    end

    describe 'the freeze option' do
      it 'specifies whether or not all parsred objects are freeze' do
        yaml = <<~'YAML'
        - [foo, bar, baz]
        - qux
        YAML

        result = YPS.safe_load(yaml)
        expect(result).not_to be_frozen
        expect(result[0]).not_to be_frozen
        expect(result[0][0]).not_to be_frozen
        expect(result[0][0]).not_to be_frozen
        expect(result[0][1]).not_to be_frozen
        expect(result[0][2]).not_to be_frozen
        expect(result[1]).not_to be_frozen

        result = YPS.safe_load(yaml, freeze: false)
        expect(result).not_to be_frozen
        expect(result[0]).not_to be_frozen
        expect(result[0][0]).not_to be_frozen
        expect(result[0][1]).not_to be_frozen
        expect(result[0][2]).not_to be_frozen
        expect(result[1]).not_to be_frozen

        result = YPS.safe_load(yaml, freeze: true)
        expect(result).to be_frozen
        expect(result[0]).to be_frozen
        expect(result[0][0]).to be_frozen
        expect(result[0][1]).to be_frozen
        expect(result[0][2]).to be_frozen
        expect(result[1]).to be_frozen
      end
    end

    describe 'the strict_integer option' do
      if RUBY_VERSION >= '3.2.0'
        it 'specifies whether or not integer values can include comma' do
          yaml = '1,000'

          result = YPS.safe_load(yaml)
          expect(result).to match_element(1000, line: 1, column: 1)

          result = YPS.safe_load(yaml, strict_integer: false)
          expect(result).to match_element(1000, line: 1, column: 1)

          result = YPS.safe_load(yaml, strict_integer: true)
          expect(result).to match_element('1,000', line: 1, column: 1)
        end
      else
        it 'is ignored' do
          yaml = '1,000'

          result = YPS.safe_load(yaml)
          expect(result).to match_element(1000, line: 1, column: 1)

          result = YPS.safe_load(yaml, strict_integer: false)
          expect(result).to match_element(1000, line: 1, column: 1)

          result = YPS.safe_load(yaml, strict_integer: true)
          expect(result).to match_element(1000, line: 1, column: 1)
        end
      end
    end
  end
end
