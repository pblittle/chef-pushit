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

begin
  require 'tailor/rake_task'
  Tailor::RakeTask.new
rescue LoadError
  warn "Tailor gem not loaded, omitting tasks"
end

task :default => [
  'tailor',
  'kitchen:all',
  'foodcritic'
]
