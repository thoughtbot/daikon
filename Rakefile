require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.ruby_opts = "-Ilib"
end

desc "run tests"
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
