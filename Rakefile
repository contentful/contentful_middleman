require 'middleman-core'

require 'rake/clean'

desc "Run tests, both RSpec and Cucumber"
task :test => [:spec]

require 'rspec/core/rake_task'
desc "Run RSpec"
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--color', '--format nested']
end

begin
  require 'cane/rake_task'

  desc "Run cane to check quality metrics"
  Cane::RakeTask.new(:quality) do |cane|
    cane.no_style = true
    cane.no_doc = true
    cane.abc_glob = "lib/contentful_middleman/**/*.rb"
  end
rescue LoadError
  # warn "cane not available, quality task not provided."
end

desc "Build HTML documentation"
task :doc do
  sh 'bundle exec yard'
end
