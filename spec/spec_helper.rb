require 'rspec'
require 'floozy'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation  # :progress, :html, :textmate
end
