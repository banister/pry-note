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

  def subcommands(cmd)
    cmd.on :add do |opt|
      opt.on :m, "message", "Provide the note inline (without opening an editor).", :argument => true
    end

    cmd.on :show  do |opt|
      opt.on :v, :verbose, "Show all notes together with source code."
    end

    cmd.on :list do |opt|
      opt.on :v, :verbose, "List all notes and content with source code."
    end
    cmd.on :export
    cmd.on :load
    cmd.on :delete do |opt|
      opt.on :all, "Delete all notes."
    end

    cmd.on :edit do |opt|
      opt.on :m, "message", "Update the note inline (without opening an editor).", :argument => true
    end
  end

  def notes() PryNote.notes ||= {} end
  def notes=(o) PryNote.notes = o; end

  # edit a note in a temporary file and return note content
  def edit_note(obj_name, initial_content=nil)
    initial_content ||= "Enter note content here for #{obj_name} (and erase this line)"
    temp_file do |f|
      f.puts(initial_content)
      f.flush
      f.close(false)
      invoke_editor(f.path, 1, false)
      File.read(f.path)
    end
  end

  def process
    if opts.command?(:add)
      cmd_opts = opts[:add]
      add_note(opts.arguments.first, cmd_opts[:message])
    elsif opts.command?(:show)
      cmd_opts = opts[:show]
      stagger_output create_note_output(opts.arguments.first, cmd_opts[:verbose])
    elsif opts.command?(:list)
      cmd_opts = opts[:list]
      if cmd_opts.present?(:verbose)
        list_all
      else
        list_notes
      end
    elsif opts.command?(:edit)
      cmd_opts = opts[:edit]
      reedit_note(opts.arguments.first, cmd_opts[:message])
    elsif opts.command?(:export)
      f = opts.arguments.first
      PryNote.export_notes(f)
      output.puts "Exported notes to #{f}"
    elsif opts.command?(:delete)
      cmd_opts = opts[:delete]
      if cmd_opts.present?(:all)
        notes.replace({})
        output.puts "Deleted all notes!"
      else
        delete_note(opts.arguments.first)
      end
    elsif opts.command?(:load)
      PryNote.load_notes(opts.arguments.first)
    else
      output.puts opts.to_s
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

  def default_object_name
    meth = Pry::Method.from_binding(target)
    if internal_binding?(target) || !meth
      obj = target.eval("self")
      obj_name = obj.is_a?(Module) ? obj.name : obj.class.name
      obj_name
    else
      meth.name_with_owner
    end
  end

  def code_object_name(co)
    co.is_a?(Pry::Method) ? co.name_with_owner : co.name
  end

  def add_note(name, message=nil)
    name ||= default_object_name
    co_name = code_object_name(retrieve_code_object_safely(name))

    if message
      note = message
    else
      note = edit_note(co_name)
    end

    notes[co_name] ||= []
    notes[co_name] << note

    output.puts "Added note to #{co_name}!"
  end

  def reedit_note(name, message=nil)
    name, note_number_s = name.split(/:(\d+)$/)
    co_name = code_object_name(retrieve_code_object_safely(name))
    raise Pry::CommandError, "No notes to edit!" if !notes[co_name]

    total_notes = notes[co_name].count
    note_number = note_number_s.to_i

    out = ""
    if !notes[co_name]
      out << "No notes to edit for #{co_name}!\n"
    elsif !note_number_s
      raise Pry::CommandError, "Must specify a note number. Allowable range is 1-#{total_notes}."
    elsif note_number < 1 || note_number > total_notes
      raise Pry::CommandError,  "Invalid note number (#{note_number}). Allowable range is 1-#{total_notes}."
    else
      if message
        new_content = message
      else
        old_content = notes[co_name][note_number.to_i - 1]
        new_content = edit_note(co_name, old_content.to_s)
      end

      notes[co_name][note_number.to_i - 1] = new_content
      out << "Updated note #{note_number} for #{co_name}!\n"
    end
  end

  def delete_note(name)
    name, note_number = name.split(/:(\d+)$/)
    co_name = code_object_name(retrieve_code_object_safely(name))

    out = ""
    if !notes[co_name]
      out << "No notes to delete for #{co_name}!\n"
    elsif note_number
      notes[co_name].delete_at(note_number.to_i - 1)
      notes.delete(co_name) if notes[co_name].empty?
      out << "Deleted note #{note_number} for #{co_name}!\n"
    else
      notes.delete(co_name)
      out << "Deleted all notes for #{text.bold(co_name)}!\n"
    end

    stagger_output out
  end

  def create_note_output(name, verbose=false)
    name ||= default_object_name
    name, _ = name.split(/:(\d+)$/)
    code_object = retrieve_code_object_safely(name)
    co_name = code_object_name(code_object)

    raise Pry::CommandError, "Please specify the name of a method or class." if !name

    if !notes.has_key?(co_name)
      raise Pry::CommandError, "No notes saved for #{text.bold(co_name)}"
    end

    out = ""
    out << text.bold("#{co_name}:\n--\n")

    if verbose
      out << Pry::Code.new(code_object.source, code_object.source_line).with_line_numbers.to_s + "\n"
    end
    notes[code_object_name(code_object)].each_with_index do |note, index|
      out << "\nNote #{text.bold((index + 1).to_s)}: #{note}"
    end

    out
  end

  def list_all
    if notes.any?
      out = ""
      out << text.bold("Showing all available notes:\n\n")
      notes.each do |key, content|
        begin
          out << create_note_output(key, true) << "\n"
        rescue
        end
      end

     else
      out << "No notes available.\n"
    end

    stagger_output out
  end

  def list_notes
    if notes.any?
      out = ""
      out << text.bold("Showing all available notes:\n\n")
      notes.each do |key, content|
        begin
          if retrieve_code_object_from_string(key, target)
            out << "#{text.bold(key)} has #{content.count} notes\n"
          end
        rescue
        end
      end

      out << "\nTo view notes for a specific item, e.g: `note show Klass#method`\n"
    else
      out << "No notes available.\n"
    end

    stagger_output out
  end
end
