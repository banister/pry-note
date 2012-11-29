reminder = proc do
  begin
    co = Pry::Helpers::CommandHelpers.retrieve_code_object_from_string(args.first.to_s, target)
    co_name = co.is_a?(Pry::Method) ? co.name_with_owner : co.name
    if PryNote.notes.keys.include?(co_name)
      output.puts "\n\n#{text.bold("Notes:")}\n--\n\n"

      PryNote.notes[co_name].each_with_index do |note, index|
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

Pry.commands.after_command("show-source", &reminder)
Pry.commands.after_command("show-doc", &reminder)

Pry.config.hooks.add_hook(:when_started, :load_notes) do
  PryNote.load_notes if PryNote.notes.empty?
end

Pry.config.hooks.add_hook(:after_session, :export_notes) do
  PryNote.export_notes
end
