require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

Dir['libraries/**/*.rb'].each { |file| require File.expand_path(file) }

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '12.04'

  config.color = true

  config.log_level = :fatal

  config.order = 'random'
end

ChefSpec::Coverage.start!
