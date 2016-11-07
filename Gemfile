source 'https://rubygems.org'

# Specify your gem's dependencies in string_tools.gemspec
gemspec

if RUBY_VERSION < '2'
  gem 'activerecord', '< 5.0'
  gem 'actionpack', '< 5.0'
  gem 'activesupport', '< 5.0'
  gem 'pry-debugger'
else
  gem 'pry-byebug'
end
