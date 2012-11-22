Pry.config.notes_file = "./notes.yml"

Pry::Commands.create_command "note" do
  description "Note stuff."

  banner <<-USAGE
    Usage: note [OPTIONS]
    Add notes to classes and methods.

    e.g note -a Pry#repl "this is my note" #=> add a note without opening editor
    e.g note -a Pry#repl   #=> add a note (with editor) to Pry#repl method
    e.g note -d Pry#repl:1 #=> delete the 1st note from Pry#repl
    e.g note -d Pry#repl   #=> delete all notes from Pry#repl
    e.g note -l            #=> list all notes
  USAGE

  def options(opt)
    opt.on :a, :add, "Add a note to a method or class.", :argument => true
    opt.on :s, :show, "Show any notes associated with the given method or class.", :argument => true
    opt.on :d, :delete, "Delete notes for a method or class.", :argument => true
    opt.on "delete-all", "Delete all notes."
    opt.on :e, :export, "Export notes to a file.", :argument => :optional
    opt.on :load, "Load notes from a file.", :argument => :optional
    opt.on :l, :list, "List all notes."
    opt.on "list-all", "List all notes with content."
  end

  def setup
    if !state.initial_setup_complete
      add_reminders
      load_notes
      state.initial_setup_complete = true
      _pry_.hooks.add_hook(:after_session, :export_notes) { export_notes }
    end
  end

  def notes
    state.notes ||= {}
  end

  # edit a note in a temporary file and return note content
  def edit_note(obj_name)
    temp_file do |f|
      f.puts("Enter note content here for #{obj_name} (and erase this line)")
      f.flush
      f.close(false)
      invoke_editor(f.path, 1, false)
      File.read(f.path)
    end
  end

  def process
    if opts.present?(:add)
      add_note(opts[:a])
    elsif opts.present?(:show)
      show_note(opts[:s])
    elsif opts.present?(:list)
      list_notes
    elsif opts.present?(:export)
      export_notes(opts[:e])
    elsif opts.present?(:delete)
      delete_note(opts[:d])
    elsif opts.present?(:"delete-all")
      notes.replace({})
    elsif opts.present?(:"list-all")
      list_all
    elsif opts.present?(:load)
      load_notes(opts[:load])
    else
      meth = Pry::Method.from_binding(target)
      if internal_binding?(target) || !meth
        obj = target.eval("self")
        obj_name = o.is_a?(Module) ? obj.name : obj.class.name
        add_note(obj_name)
      else
        add_note(meth.name_with_owner)
      end
    end
  end

  def retrieve_code_object_safely(name)
    code_object = retrieve_code_object_from_string(name, target)

    if !code_object
      raise Pry::CommandError, "No code object found named #{name}"
    elsif code_object.name.to_s == ""
      raise Pry::CommandError, "Object #{name} doesn't have a proper name, can't create note"
    end

    code_object
  end

  def code_object_name(co)
    co.is_a?(Pry::Method) ? co.name_with_owner : co.name
  end

  def add_note(name)
    co_name = code_object_name(retrieve_code_object_safely(name))

    if args.any?
      note = args.join(" ")
    else
      note = edit_note(co_name)
    end

    notes[co_name] ||= []
    notes[co_name] << note

    output.puts "Added note to #{co_name}!"
  end

  def delete_note(name)
    name, note_number = name.split(":")
    co_name = code_object_name(retrieve_code_object_safely(name))

    if !notes[co_name]
      output.puts "No notes to delete for #{co_name}!"
    elsif note_number
      notes[co_name].delete_at(note_number.to_i - 1)
      notes.delete(co_name) if notes[co_name].empty?
      output.puts "Deleted note #{note_number} for #{co_name}!"
    else
      notes.delete(co_name)
      output.puts "Deleted all notes for #{text.bold(co_name)}!"
    end
  end

  def show_note(name)
    code_object = retrieve_code_object_safely(name)

    co_name = code_object_name(code_object)

    if !notes.has_key?(co_name)
      output.puts "No notes saved for #{text.bold(co_name)}"
      return
    end

    output.puts text.bold("#{co_name}:\n--")

    notes[code_object_name(code_object)].each_with_index do |note, index|
      output.puts "\nNote #{text.bold((index + 1).to_s)}: #{note}"
    end
  end

  def export_notes(file_name=nil)
    require 'yaml'
    file_name ||= Pry.config.notes_file

    expanded_path = File.expand_path(file_name)
    File.open(expanded_path, "w") { |f| f.puts YAML.dump(notes) }
    output.puts "Exported notes to #{expanded_path}!"
  end

  def load_notes(file_name=nil)
    require 'yaml'
    file_name ||= Pry.config.notes_file

    expanded_path = File.expand_path(file_name)
    if File.exists?(expanded_path)
      notes.replace YAML.load File.read(expanded_path)
    end
  end

  def list_all
    if notes.any?
      output.puts text.bold("Showing all available notes:\n\n")
      notes.each do |key, content|
        begin
          show_note(key)
          output.puts "\n"
        rescue
        end
      end

      output.puts "\nTo view notes for an item type, e.g: `note -s Klass#method`"
    else
      output.puts "No notes available."
    end
  end

  def list_notes
    if notes.any?
      output.puts text.bold("Showing all available notes:\n\n")
      notes.each do |key, content|
        if retrieve_code_object_from_string(key, target)
          output.puts "#{text.bold(key)} has #{content.count} notes"
        end
      end

      output.puts "\nTo view notes for an item type, e.g: `note -s Klass#method`"
    else
      output.puts "No notes available."
    end
  end

  def add_reminders
    me = self
    reminder = proc do
      begin
        code_object = retrieve_code_object_from_string(args.first.to_s, target)
        if me.notes.keys.include?(me.code_object_name(code_object))
          co_name = me.code_object_name(code_object)
          output.puts "\n\n#{text.bold("Notes:")}\n--\n\n"

          me.notes[me.code_object_name(code_object)].each_with_index do |note, index|
            clipped_note = note.lines.count < 3  ? note : note.lines.to_a[0..2].join +
              text.bold("<...clipped...>") + " Use `note -s #{co_name}` to view unelided notes."
            amended_note = clipped_note.lines.each_with_index.map do |line, idx|
              idx > 0 ? "#{' ' * ((index + 1).to_s.size + 2)}#{line}" : line
            end.join
            output.puts "#{text.bold((index + 1).to_s)}. #{amended_note}"
          end

        end
      rescue
      end
    end

    _pry_.commands.after_command("show-source", &reminder)
    _pry_.commands.after_command("show-doc", &reminder)
  end
end
