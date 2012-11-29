require 'yaml'
require 'pry-note/version'
require 'pry-note/hooks'
require 'pry-note/commands'

Pry.config.notes_file = "./notes.yml"

module PryNote
  def self.notes() @notes ||= {}; end
  def self.notes=(o) @notes = o; end

  def self.load_notes(file_name=nil)
    return if !file_name && !Pry.config.notes_file
    file_name ||= Pry.config.notes_file
    expanded_path = File.expand_path(file_name)
    if File.exists?(expanded_path)
      PryNote.notes = YAML.load File.read(expanded_path)
    end
  end

  def self.export_notes(file_name=nil)
    return if !file_name && !Pry.config.notes_file
    file_name ||= Pry.config.notes_file
    expanded_path = File.expand_path(file_name)
    File.open(expanded_path, "w") { |f| f.puts YAML.dump(PryNote.notes) }
  end
end
