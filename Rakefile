#!/usr/bin/env rake

require 'rake'

begin
  require 'foodcritic'
  FoodCritic::Rake::LintTask.new do |t|
    t.options = { :fail_tags => ['any'] }
  end
rescue LoadError
  warn "FoodCritic gem not loaded, omitting tasks"
end

begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts "Kitchen gem not loaded, omitting tasks" unless ENV['CI']
end

task :default => [
  'kitchen:all',
  'foodcritic'
]
