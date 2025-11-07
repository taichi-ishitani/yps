# frozen_string_literal: true

RSpec.describe YPS do
  def have_position_info(line:, column:, filename: nil)
    have_attributes(position: have_attributes(line:, column:, filename:))
  end

  def match_element(value_or_matcher, line:, column:, filename: nil)
    matcher =
      if value_or_matcher.is_a? RSpec::Matchers::BuiltIn::BaseMatcher
        value_or_matcher
      else
        eq(value_or_matcher)
      end
    matcher.and have_position_info(line:, column:, filename:)
  end

  def be_nil_element(line:, column:, filename: nil)
    have_attributes(value: be_nil).and have_position_info(line:, column:, filename:)
  end

  def be_false_element(line:, column:, filename: nil)
    have_attributes(value: equal(false)).and have_position_info(line:, column:, filename:)
  end

  def file_fixture_path(filename)
    File.join(__dir__, 'fixtures', filename)
  end

  def read_file_fixure(filename)
    File.read(file_fixture_path(filename))
  end

  shared_examples 'an YAML loader' do |safe_loader:, file_input:, multiple_documents:|
    it 'parses the given YAML and add position information to each parsed elements' do
      result, filename = load_fixture('basic.yaml')

      expect(result).to have_position_info(line: 1, column: 1, filename:)
      expect(result['children']).to have_position_info(line: 2, column: 3, filename:)

      expect(result['children'][0]).to have_position_info(line: 2, column: 5, filename:)
      expect(result['children'][0]['name']).to match_element('Kanta', line: 2, column: 11, filename:)
      expect(result['children'][0]['age']).to match_element(8, line: 3, column: 10, filename:)

      expect(result['children'][1]).to have_position_info(line: 4, column: 5, filename:)
      expect(result['children'][1]['name']).to match_element('Kaede', line: 4, column: 11, filename:)
      expect(result['children'][1]['age']).to match_element(3, line: 5, column: 10, filename:)
    end

    if safe_loader
      specify 'Symbol is not allowed to be load by default' do
        expect { load_fixture('symbols.yaml') }.to raise_error Psych::DisallowedClass
      end
    else
      specify 'Symbol is allowed to be load by default' do
        result, filename = load_fixture('symbols.yaml')
        expect(result[0]).to match_element(:foo, line: 1, column: 3, filename:)
        expect(result[1]).to match_element(:bar, line: 2, column: 3, filename:)
      end
    end

    context 'when the given YAML contains multiple documents' do
      if multiple_documents
        it 'parses all documents' do
          result, filename = load_fixture('multiple_documents.yaml', multiple_documents: true)

          expect(result[0]).to have_position_info(line: 2, column: 1, filename:)
          expect(result[0][0]).to match_element('foo', line: 2, column: 3, filename:)
          expect(result[0][1]).to match_element('bar', line: 3, column: 3, filename:)

          expect(result[1]).to have_position_info(line: 5, column: 1, filename:)
          expect(result[1][0]).to match_element('baz', line: 5, column: 3, filename:)
          expect(result[1][1]).to match_element('qux', line: 6, column: 3, filename:)

          expect(result[2]).to be_nil_element(line: 8, column: 1, filename:)
        end
      else
        it 'parses the 1st documents only' do
          result, filename = load_fixture('multiple_documents.yaml', multiple_documents: true)

          expect(result.size).to eq 2
          expect(result).to have_position_info(line: 2, column: 1, filename:)
          expect(result[0]).to match_element('foo', line: 2, column: 3, filename:)
          expect(result[1]).to match_element('bar', line: 3, column: 3, filename:)

        end
      end
    end

    describe 'the permitted_classes option' do
      it 'specifies additonal classed which are allowed to be loaded' do
        expect { load_fixture('permitted_classes.yaml') }.to raise_error Psych::DisallowedClass

        result, filename = load_fixture('permitted_classes.yaml', permitted_classes: [Symbol, Date])
        expect(result[0]).to match_element(Date.new(2025, 9, 28), line: 1, column: 3, filename:)
        expect(result[1]).to match_element(:foo, line: 2, column: 3, filename:)
      end
    end

    describe 'the permitted_symbols option' do
      context 'when no symbols are specified' do
        specify 'any symbols can be loaded' do
          result, filename = load_fixture('symbols.yaml', permitted_classes: [Symbol])
          expect(result[0]).to match_element(:foo, line: 1, column: 3, filename:)
          expect(result[1]).to match_element(:bar, line: 2, column: 3, filename:)
        end
      end

      context 'when symbols are specified' do
        specify 'the given symbols can only be loaded' do
          expect {
            load_fixture(
              'symbols.yaml',
              permitted_classes: [Symbol], permitted_symbols: [:foo]
            )
          }.to raise_error Psych::DisallowedClass

          result, filename =
            load_fixture(
              'symbols.yaml',
              permitted_classes: [Symbol], permitted_symbols: [:foo, :bar]
            )
          expect(result[0]).to match_element(:foo, line: 1, column: 3, filename:)
          expect(result[1]).to match_element(:bar, line: 2, column: 3, filename:)
        end
      end
    end

    describe 'the unwrapped_classes option' do
      it 'specified classes whose objects are not wrapped with the wrapper class' do
        result, filename = load_fixture('unwrapped_classes.yaml')
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result[0]).to be_nil_element(line: 1, column: 3, filename:)
        expect(result[1]).to be_false_element(line: 2, column: 3, filename:)

        result, filename = load_fixture('unwrapped_classes.yaml', unwrapped_classes: [NilClass, FalseClass])
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result[0]).to be_nil
        expect(result[1]).to equal(false)
      end
    end

    describe 'the aliases option' do
      it 'specifies whether or not aliases can be explicitly allowed' do
        error_class = RUBY_VERSION >= '3.2.0' && Psych::AliasesNotEnabled || Psych::BadAlias
        expect { load_fixture('aliases.yaml') }.to raise_error error_class
        expect { load_fixture('aliases.yaml', aliases: false) }.to raise_error error_class

        result, filename = load_fixture('aliases.yaml', aliases: true)
        expect(result[0]).to have_position_info(line: 1, column: 3, filename:)
        expect(result[0][0]).to match_element('foo', line: 2, column: 5, filename:)
        expect(result[0][1]).to match_element('bar', line: 3, column: 5, filename:)
        expect(result[1]).to have_position_info(line: 4, column: 3, filename:)
        expect(result[1][0]).to match_element('foo', line: 2, column: 5, filename:)
        expect(result[1][1]).to match_element('bar', line: 3, column: 5, filename:)
      end
    end

    unless file_input
      describe 'the filename option' do
        specify 'the file name given by this option will be added to each position info' do
          filename = 'test.yaml'
          result, _ = load_fixture('basic.yaml', filename:)

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
    end

    describe 'the fallback option' do
      if multiple_documents
        specify 'the default fallback object is an empty array' do
          result, _ = load_fixture('empty.yaml', check_fallback: true)
          expect(result).to be_instance_of(Array).and be_empty
        end
      else
        specify 'the default fallback object is nil' do
          result, _ = load_fixture('empty.yaml', check_fallback: true)
          expect(result).to be_nil
        end
      end
      it 'specifies the return value which will be returned when an empty YAML is given' do
        fallback = Object.new
        result, _ = load_fixture('empty.yaml', check_fallback: true, fallback:)
        expect(result).to equal(fallback)
      end
    end

    describe 'the symbolize_names option' do
      it 'specifies whether or not all mapping keys will be converted into Symbol' do
        result, filename = load_fixture('symbolize_names.yaml')
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result['foo']).to have_position_info(line: 2, column: 3, filename:)
        expect(result['foo'][0]).to have_position_info(line: 2, column: 5, filename:)
        expect(result['foo'][0]['bar']).to match_element(0, line: 2, column: 10, filename:)
        expect(result['foo'][0]['baz']).to match_element(1, line: 3, column: 10, filename:)
        expect(result['foo'][1]).to have_position_info(line: 4, column: 5, filename:)
        expect(result['foo'][1]['qux']).to match_element(2, line: 4, column: 10, filename:)
        expect(result['foo'][1]['quu']).to match_element(3, line: 5, column: 10, filename:)

        result, filename = load_fixture('symbolize_names.yaml', symbolize_names: false)
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result['foo']).to have_position_info(line: 2, column: 3, filename:)
        expect(result['foo'][0]).to have_position_info(line: 2, column: 5, filename:)
        expect(result['foo'][0]['bar']).to match_element(0, line: 2, column: 10, filename:)
        expect(result['foo'][0]['baz']).to match_element(1, line: 3, column: 10, filename:)
        expect(result['foo'][1]).to have_position_info(line: 4, column: 5, filename:)
        expect(result['foo'][1]['qux']).to match_element(2, line: 4, column: 10, filename:)
        expect(result['foo'][1]['quu']).to match_element(3, line: 5, column: 10, filename:)

        result, filename = load_fixture('symbolize_names.yaml', symbolize_names: true)
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result[:foo]).to have_position_info(line: 2, column: 3, filename:)
        expect(result[:foo][0]).to have_position_info(line: 2, column: 5, filename:)
        expect(result[:foo][0][:bar]).to match_element(0, line: 2, column: 10, filename:)
        expect(result[:foo][0][:baz]).to match_element(1, line: 3, column: 10, filename:)
        expect(result[:foo][1]).to have_position_info(line: 4, column: 5, filename:)
        expect(result[:foo][1][:qux]).to match_element(2, line: 4, column: 10, filename:)
        expect(result[:foo][1][:quu]).to match_element(3, line: 5, column: 10, filename:)
      end
    end

    describe 'the freeze option' do
      it 'specifies whether or not all parsred objects are freeze' do
        result, filename = load_fixture('freeze.yaml')
        expect(result).to match_element(be_mutable, line: 1, column: 1, filename:)
        expect(result[0]).to match_element(be_mutable, line: 1, column: 3, filename:)
        expect(result[0][0]).to match_element(be_mutable, line: 1, column: 4, filename:)
        expect(result[0][1]).to match_element(be_mutable, line: 1, column: 9, filename:)
        expect(result[1]).to match_element(be_mutable, line: 2, column: 3, filename:)

        result, filename = load_fixture('freeze.yaml', freeze: false)
        expect(result).to match_element(be_mutable, line: 1, column: 1, filename:)
        expect(result[0]).to match_element(be_mutable, line: 1, column: 3, filename:)
        expect(result[0][0]).to match_element(be_mutable, line: 1, column: 4, filename:)
        expect(result[0][1]).to match_element(be_mutable, line: 1, column: 9, filename:)
        expect(result[1]).to match_element(be_mutable, line: 2, column: 3, filename:)

        result, filename = load_fixture('freeze.yaml', freeze: true)
        expect(result).to match_element(be_frozen, line: 1, column: 1, filename:)
        expect(result[0]).to match_element(be_frozen, line: 1, column: 3, filename:)
        expect(result[0][0]).to match_element(be_frozen, line: 1, column: 4, filename:)
        expect(result[0][1]).to match_element(be_frozen, line: 1, column: 9, filename:)
        expect(result[1]).to match_element(be_frozen, line: 2, column: 3, filename:)
      end
    end

    describe 'the strict_integer option' do
      if RUBY_VERSION >= '3.2.0'
        it 'specifies whether or not integer values can include comma' do
          result, filename = load_fixture('strict_integer.yaml')
          expect(result).to match_element(1000, line: 1, column: 1, filename:)

          result, filename = load_fixture('strict_integer.yaml', strict_integer: false)
          expect(result).to match_element(1000, line: 1, column: 1, filename:)

          result, filename = load_fixture('strict_integer.yaml', strict_integer: true)
          expect(result).to match_element('1,000', line: 1, column: 1, filename:)
        end
      else
        it 'is ignored' do
          result, filename = load_fixture('strict_integer.yaml')
          expect(result).to match_element(1000, line: 1, column: 1, filename:)

          result, filename = load_fixture('strict_integer.yaml', strict_integer: false)
          expect(result).to match_element(1000, line: 1, column: 1, filename:)

          result, filename = load_fixture('strict_integer.yaml', strict_integer: true)
          expect(result).to match_element(1000, line: 1, column: 1, filename:)
        end
      end
    end

    describe 'the value_class option' do
      def match_value(value, line:, column:, filename:)
        have_attributes(value: eq(value)).and have_position_info(line:, column:, filename:)
      end

      it 'specifies the class wrapping parsed elements' do
        klass = Struct.new(:value, :position)

        result, filename = load_fixture('basic.yaml', value_class: klass)
        expect(result).to have_position_info(line: 1, column: 1, filename:)
        expect(result.value['children']).to have_position_info(line: 2, column: 3, filename:)

        expect(result.value['children'].value[0])
          .to have_position_info(line: 2, column: 5, filename:)
        expect(result.value['children'].value[0].value['name'])
          .to match_value('Kanta', line: 2, column: 11, filename:)
        expect(result.value['children'].value[0].value['age'])
          .to match_value(8, line: 3, column: 10, filename:)

        expect(result.value['children'].value[1])
          .to have_position_info(line: 4, column: 5, filename:)
        expect(result.value['children'].value[1].value['name'])
          .to match_value('Kaede', line: 4, column: 11, filename:)
        expect(result.value['children'].value[1].value['age'])
          .to match_value(3, line: 5, column: 10, filename:)
      end
    end
  end

  describe '.safe_load' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      yaml = read_file_fixure(filename)
      [YPS.safe_load(yaml, **kwargs)]
    end

    it_behaves_like 'an YAML loader', safe_loader: true, file_input: false, multiple_documents: false
  end

  describe '.load' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      yaml = read_file_fixure(filename)
      [YPS.load(yaml, **kwargs)]
    end

    it_behaves_like 'an YAML loader', safe_loader: false, file_input: false, multiple_documents: false
  end

  describe '.safe_load_file' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      path = file_fixture_path(filename)
      [YPS.safe_load_file(path, **kwargs), path]
    end

    it_behaves_like 'an YAML loader', safe_loader: true, file_input: true, multiple_documents: false
  end

  describe '.load_file' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      path = file_fixture_path(filename)
      [YPS.load_file(path, **kwargs), path]
    end

    it_behaves_like 'an YAML loader', safe_loader: false, file_input: true, multiple_documents: false
  end

  describe '.safe_load_stream' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      yaml = read_file_fixure(filename)
      if multiple_documents || check_fallback
        [YPS.safe_load_stream(yaml, **kwargs)]
      else
        [YPS.safe_load_stream(yaml, **kwargs).first]
      end
    end

    it_behaves_like 'an YAML loader', safe_loader: true, file_input: false, multiple_documents: true
  end

  describe '.load_stream' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      yaml = read_file_fixure(filename)
      if multiple_documents || check_fallback
        [YPS.load_stream(yaml, **kwargs)]
      else
        [YPS.load_stream(yaml, **kwargs).first]
      end
    end

    it_behaves_like 'an YAML loader', safe_loader: false, file_input: false, multiple_documents: true
  end

  describe '.safe_load_stream_file' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      path = file_fixture_path(filename)
      if multiple_documents || check_fallback
        [YPS.safe_load_stream_file(path, **kwargs), path]
      else
        [YPS.safe_load_stream_file(path, **kwargs).first, path]
      end
    end

    it_behaves_like 'an YAML loader', safe_loader: true, file_input: true, multiple_documents: true
  end

  describe '.load_stream_file' do
    def load_fixture(filename, multiple_documents: false, check_fallback: false, **kwargs)
      path = file_fixture_path(filename)
      if multiple_documents || check_fallback
        [YPS.load_stream_file(path, **kwargs), path]
      else
        [YPS.load_stream_file(path, **kwargs).first, path]
      end
    end

    it_behaves_like 'an YAML loader', safe_loader: false, file_input: true, multiple_documents: true
  end
end
