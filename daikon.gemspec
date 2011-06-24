require './lib/daikon/version'

Gem::Specification.new do |s|
  s.name = %q{daikon}
  s.version = Daikon::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ['Nick Quaranto', 'thoughtbot']
  s.date = %q{2011-06-24}
  s.description = %q{daikon, a radishapp.com client}
  s.email = %q{nick@thoughtbot.com}
  s.executables = [%q{daikon}]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Appraisals",
    "Gemfile",
    "Gemfile.lock",
    "MIT-LICENSE",
    "README.rdoc",
    "Rakefile",
    "bin/daikon",
    "daikon.gemspec"
  ] + Dir["lib/**/*.rb"]
  s.homepage = %q{http://github.com/qrush/daikon}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = %q{1.8.1}
  s.summary = %q{daikon, a radishapp.com client}
  s.test_files =
    Dir["gemfiles/**/*"] +
    Dir["spec/**/*"] +
    Dir["features/**/*"]

  s.add_runtime_dependency(%q<daemons>, ["~> 1.0"])
  s.add_runtime_dependency(%q<excon>, ["~> 0.5"])
  s.add_runtime_dependency(%q<json_pure>, ["~> 1.4"])
  s.add_runtime_dependency(%q<redis>, ["~> 2.1"])
  s.add_development_dependency(%q<bourne>, [">= 0"])
  s.add_development_dependency(%q<cucumber>, [">= 0"])
  s.add_development_dependency(%q<jeweler>, [">= 0"])
  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<timecop>, [">= 0"])
end
