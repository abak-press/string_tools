# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end

require 'string_tools'
