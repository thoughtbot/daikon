require 'appraisal'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.ruby_opts = "-Ilib"
end

Cucumber::Rake::Task.new(:features)

desc "run tests"
task :default => [:spec, :features]

desc "test all appraisals"
task :all do
  appraisals =
    %w[redis2-1   redis2-2
       daemons1-0 daemons1-1].map do |run|
    "bundle exec rake appraisal:#{run}"
  end

  sh "bundle exec rake appraisal:install"
  sh appraisals.join(' && ')
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
  def parse_monitor
    monitor = Daikon::Monitor.new(nil, nil)

    File.open("monitor.log", "r") do |f|
      until f.eof?
        monitor.parse(f.readline)
      end
    end
  end

  require 'perftools'
  PerfTools::CpuProfiler.start("daikon.profile") do
    parse_monitor
  end
end
