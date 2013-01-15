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

    if PryNote.notes && PryNote.notes.any?
      File.open(expanded_path, "w") { |f| f.puts YAML.dump(PryNote.notes) }
    end
  end

  # @return [Pry::Method, Pry::WrappedModule, Pry::Command] The code_object
  def self.retrieve_code_object_safely(name, _pry_)
    code_object = Pry::CodeObject.lookup(name, _pry_)

    if !code_object
      raise Pry::CommandError, "No code object found named #{name}"
    elsif code_object.name.to_s == ""
      raise Pry::CommandError, "Object #{name} doesn't have a proper name, can't create note"
    end

    code_object
  end

  # @return [String] the `name` of the code object
  def self.code_object_name(co)
    if co.is_a?(Pry::Method)
      co.name_with_owner
    elsif co.is_a?(Pry::WrappedModule)
      co.name
    elsif co <= Pry::Command
      co.command_name
    end
  end
end
