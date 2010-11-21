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

  gem.add_runtime_dependency "daemons",            "~> 1.1.0"
  gem.add_runtime_dependency "json_pure",          "~> 1.4.6"
  gem.add_runtime_dependency "net-http-peristent", "~> 1.4.1"
  gem.add_runtime_dependency "redis",              "~> 2.1.1"
  gem.add_runtime_dependency "SystemTimer",        "~> 1.2.1"

  gem.add_development_dependency "rspec",    "~> 2.1.0"
  gem.add_development_dependency "cucumber", ">= 0"
  gem.add_development_dependency "bundler",  "~> 1.0.0"
  gem.add_development_dependency "jeweler",  "~> 1.5.1"
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
