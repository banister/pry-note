Pry-note
========

__Ease refactoring and exploration by attaching notes to methods and classes in Pry__

**NOTE: This only works on Pry HEAD currently (v0.9.11+)**

```
[1] pry(main)> note -h
  add
    -m, --message      Provide the note inline (without opening an editor).

  show
    -v, --verbose      Show all notes together with source code.

  list
    -v, --verbose      List all notes and content with source code.

  delete
        --all      Delete all notes.

  edit
    -m, --message      Update the note inline (without opening an editor).

  Other options
Usage: note [OPTIONS]
Add notes to classes and methods.

e.g note add Pry#repl -m "this is my note" #=> add a note without opening editor
e.g note add Pry#repl   #=> add a note (with editor) to Pry#repl method
e.g note delete Pry#repl:1 #=> delete the 1st note from Pry#repl
e.g note delete Pry#repl   #=> delete all notes from Pry#repl
e.g note list            #=> list all notes

    -h, --help      Show this message.
```


See the following showterm for an example session: http://showterm.io/c194f02da5545e9210cb9#fast