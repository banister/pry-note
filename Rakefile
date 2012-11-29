$:.unshift 'lib'

dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-note"

require 'rake/clean'
require 'rubygems/package_task'
require "#{PROJECT_NAME}/version"

CLOBBER.include("**/*~", "**/*#*", "**/*.log")
CLEAN.include("**/*#*", "**/*#*.*", "**/*_flymake*.*", "**/*_flymake",
              "**/*.rbc", "**/.#*.*")

def apply_spec_defaults(s)
  s.name = PROJECT_NAME
  s.summary = "Ease refactoring and exploration by attaching notes to methods and classes in Pry"
  s.version = PryNote::VERSION
  s.date = Time.now.strftime '%Y-%m-%d'
  s.author = "John Mair (banisterfiend)"
  s.email = 'jrmair@gmail.com'
  s.description = s.summary
  s.require_path = 'lib'
  s.add_development_dependency('rake', '~> 0.9')
  s.homepage = "https://github.com/banister"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
end

desc "Set up and run tests"
task :default => [:test]


desc "run pry with plugin enabled"
task :pry do
  exec("pry -rubygems -I#{direc}/lib/ -r #{direc}/lib/#{PROJECT_NAME}")
end

desc "Run tests"
task :test do
  sh "bacon -Itest -rubygems -a -q"
end
task :spec => :test

desc "Show version"
task :version do
  puts "Pry-note version: #{PryNote::VERSION}"
end

desc "generate gemspec"
task :gemspec => "ruby:gemspec"

namespace :ruby do
  spec = Gem::Specification.new do |s|
    apply_spec_defaults(s)
    s.platform = Gem::Platform::RUBY
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end

  desc  "Generate gemspec file"
  task :gemspec do
    File.open("#{spec.name}.gemspec", "w") do |f|
      f << spec.to_ruby
    end
  end
end

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, :gemspec, "ruby:gem"]

desc "remove all platform gems"
task :rmgems => ["ruby:clobber_package"]

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall pry-note" rescue nil
  sh "gem install #{direc}/pkg/#{PROJECT_NAME}-#{PryNote::VERSION}.gem"
end

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{File.dirname(__FILE__)}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end
