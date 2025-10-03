# frozen_string_literal: true

require_relative 'lib/yps/version'

Gem::Specification.new do |spec|
  spec.name = 'yps'
  spec.version = YPS::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['taichi730@gmail.com']

  spec.summary = 'YPS: YAML Positioning System'
  spec.description = 'YPS is a gem to parse YAML and add position information (file name, line and column) ' \
                     'to each parsed elements. This is useful for error reporting and debugging, ' \
                     'allowing developers to precisely locate an issue within the original YAML file.'
  spec.homepage = 'https://github.com/taichi-ishitani/yps'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = 'https://taichi-ishitani.github.io/yps/'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z lib *.md *.txt`.split("\x0")
  end

  spec.require_paths = ['lib']

  spec.extra_rdoc_files += spec.files.grep(%r{\A[^/]+\.(?:txt|md)\z})
  spec.rdoc_options = [
    '--main', 'README.md',
    '--title', spec.summary,
    '--show-hash',
    '--line-numbers'
  ]
end
