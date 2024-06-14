# frozen_string_literal: true

source 'https://rubygems.org'
ruby file: '.ruby-version'

gem 'gr-plot'
gem 'slop', '>= 3.5.1'
gem 'unitwise', '>= 1.1.0'

group :test do
  gem 'minitest'
end
gem 'rubocop', group: 'development', require: false

# These gems will not be included by default in Ruby 3.4, so they cause annoying warnings unless you include them
gem 'mutex_m'
gem 'bigdecimal'
