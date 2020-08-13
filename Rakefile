require "rubygems"
require "bundler/setup"
require "bump"

NAME = Dir["*.gemspec"].first.split(".").first.freeze
VERSION = CarbonCopy::VERSION
GEM_FILE = "#{NAME}-#{VERSION}.gem".freeze
GEMSPEC_FILE = "#{NAME}.gemspec".freeze

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.markup = "tomdoc"
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :bump do
  current_version = Bump::Bump.current

  %w[major minor patch pre].each do |bump|
    version = Bump::Bump.next_version(bump)
    desc "Bump v#{current_version} to v#{version}"
    task bump do
      Bump::Bump.run(bump, commit: false)
    end
  end

  desc "Bump v#{current_version} to $VERSION"
  task :set do
    unless /\S/.match?(ENV["VERSION"])
      puts "ERROR: version can't be blank"
      exit 1
    end

    Bump::Bump.run("set", commit: false, version: ENV["VERSION"])
  end
end

desc "Build #{GEM_FILE} into the pkg directory"
task :build do
  sh "mkdir -p pkg"
  sh "gem build #{GEMSPEC_FILE}"
  sh "mv #{GEM_FILE} pkg"
end

desc "Create tag v#{VERSION} and build and push #{GEM_FILE} to Rubygems"
task release: [:spec, :build] do
  unless /^\* master$/.match?(`git branch`)
    puts "You must be on the master branch to release!"
    exit!
  end
  sh "git commit --allow-empty -a -e -m 'Release #{VERSION}'"
  sh "git tag v#{VERSION}"
  sh "git push origin master"
  sh "git push origin v#{VERSION}"
  sh "gem push pkg/#{GEM_FILE}"
end
