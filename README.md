[![Gem Version](https://badge.fury.io/rb/yps.svg)](https://badge.fury.io/rb/yps)
[![CI](https://github.com/taichi-ishitani/yps/actions/workflows/ci.yml/badge.svg)](https://github.com/taichi-ishitani/yps/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/gh/taichi-ishitani/projects/yps/maintainability.svg)](https://qlty.sh/gh/taichi-ishitani/projects/yps)
[![codecov](https://codecov.io/gh/taichi-ishitani/yps/graph/badge.svg?token=JwmT4kfLYG)](https://codecov.io/gh/taichi-ishitani/yps)

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A231E3I)

# YPS: YAML Positioning System

YPS is a gem to parse YAML and add position information (file name, line and column) to each parsed elements.
This is useful for error reporting and debugging, allowing developers to precisely locate an issue within the original YAML file.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add yps
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install yps
```

## Usage

You can use the methods below to load a YAML code into Ruby objects with their position information (file name, line, and column).

* `YPS.safe_load`/`YPS.load`
    * Load the given YAML string into Ruby objects with position information.
* `YPS.safe_load_file`/`YPS.load_file`
    * Load the YAML code read from the given file path into Ruby objects with position information.

Parsed objects, except for hash keys, have their own position information.
You can use the `position` method to get position information in the original YAML of the receiver object.

```ruby
require 'yps'

yaml = YPS.load(<<~'YAML')
children:
  - name: kanta
    age: 8
  - name: kaede
    age: 3
YAML

# output
# name: kanta (filename: unknown line 2 column 11)
# age: 8 (filename: unknown line 3 column 10)
# name: kaede (filename: unknown line 4 column 11)
# age: 3 (filename: unknown line 5 column 10)
yaml['children'].each do |child|
  child.each do |key, value|
    puts "#{key}: #{value} (#{value.position})"
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/taichi-ishitani/yps.

* [Issue Tracker](https://github.com/taichi-ishitani/yps/issues)
* [Pull Requesst](https://github.com/taichi-ishitani/yps/pulls)
* [Discussion](https://github.com/taichi-ishitani/yps/discussions)

## Copyright & License

Copyright &copy; 2025 Taichi Ishitani.
YPS is licensed under the terms of the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE.txt](LICENSE.txt) for further details.

## Code of Conduct

Everyone interacting in the YPS project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/taichi-ishitani/yps/blob/master/CODE_OF_CONDUCT.md).
