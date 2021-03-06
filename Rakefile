require 'rubygems'
require 'jeweler'
require './lib/daikon'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = Daikon::VERSION

  gem.name = "daikon"
  gem.homepage = "http://github.com/qrush/daikon"
  gem.license = "MIT"
  gem.summary = gem.description = %Q{daikon, a radishapp.com client}
  gem.email = "nick@quaran.to"
  gem.authors = ["Nick Quaranto"]
  gem.required_ruby_version = '>= 1.8.7'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

def parse_monitor
  monitor = Daikon::Monitor.new(nil, nil)

  File.open("monitor.log", "r") do |f|
    until f.eof?
      monitor.parse(f.readline)
    end
  end
end

desc "benchmark monitor.log against the monitor parsing"
task :bench do
  require 'benchmark'
  Benchmark.bm do |bm|
    bm.report do
      parse_monitor
    end
  end
end

desc "perf tools the monitor.log"
task :perf do
  require 'perftools'
  PerfTools::CpuProfiler.start("daikon.profile") do
    parse_monitor
  end
end
