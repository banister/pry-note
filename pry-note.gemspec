# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pry-note"
  s.version = "0.2.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2012-12-12"
  s.description = "Ease refactoring and exploration by attaching notes to methods and classes in Pry"
  s.email = "jrmair@gmail.com"
  s.files = ["README.md", "Rakefile", "lib/pry-note.rb", "lib/pry-note/commands.rb", "lib/pry-note/hooks.rb", "lib/pry-note/version.rb", "pry-note.gemspec", "test/helper.rb", "test/test_pry_note.rb"]
  s.homepage = "https://github.com/banister"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Ease refactoring and exploration by attaching notes to methods and classes in Pry"
  s.test_files = ["test/helper.rb", "test/test_pry_note.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
    else
      s.add_dependency(%q<rake>, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 0.9"])
  end
end
