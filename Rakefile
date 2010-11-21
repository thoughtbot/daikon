require 'rubygems'
require 'jeweler'
require 'lib/daikon'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = Daikon::VERSION

  gem.name = "daikon"
  gem.homepage = "http://github.com/qrush/daikon"
  gem.license = "MIT"
  gem.summary = gem.description = %Q{daikon, a radishapp.com client}
  gem.email = "nick@quaran.to"
  gem.authors = ["Nick Quaranto"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :spec
