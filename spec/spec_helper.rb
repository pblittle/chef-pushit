require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'
require_relative '../libraries/chef_pushit_app'
require_relative '../libraries/chef_pushit'

Dir['libraries/**/*.rb'].each { |file| require File.expand_path(file) }

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '12.04'

  config.color = true

  config.log_level = :fatal

  config.order = 'random'

  Dir['spec/support/shared/**/*.rb'].each { |file| require file }
end

at_exit { ChefSpec::Coverage.report! }
