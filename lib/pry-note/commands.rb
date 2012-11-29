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
      opt.on :m, "message", "Show the list of all available plugins", :argument => true
    end

    cmd.on :show
    cmd.on :list do |opt|
      opt.on :v, :verbose, "List all notes and content with source code"
    end
    cmd.on :export
    cmd.on :load
    cmd.on :delete do |opt|
      opt.on :all, "Delete all notes."
    end
  end

  def options(opt)
    opt.on :a, :add, "Add a note to a method or class.", :argument => true
    opt.on :s, :show, "Show any notes associated with the given method or class.", :argument => true
    opt.on :d, :delete, "Delete notes for a method or class.", :argument => true
    opt.on "delete-all", "Delete all notes."
    opt.on "list-all", "List all notes with content."
  end

  def notes() PryNote.notes ||= {} end
  def notes=(o) PryNote.notes = o; end

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
    if opts.command?(:add)
      cmd_opts = opts[:add]
      add_note(opts.arguments.first, cmd_opts[:message])
    elsif opts.command?(:show)
      show_note(opts.arguments.first)
    elsif opts.command?(:list)
      cmd_opts = opts[:list]
      if cmd_opts.present?(:verbose)
        list_all
      else
        list_notes
      end
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
    name, line_number = name.split(/@(\d+)$/)


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

  def delete_note(name)
    name, note_number = name.split(/:(\d+)$/)
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
    output.puts Pry::Code.new(code_object.source, code_object.source_line).with_line_numbers.to_s
    notes[code_object_name(code_object)].each_with_index do |note, index|
      output.puts "\nNote #{text.bold((index + 1).to_s)}: #{note}"
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
end
