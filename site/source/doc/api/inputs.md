---
title: howl.inputs
---

# howl.inputs

## Overview

Inputs are used for controlling user input. The most common use of inputs is
when defining commands using the [command] module, but they can also be used
when working directly with [Readline] instances.

An input is at its core nothing more than a table of callback functions. As the
user interacts with the Readline, the various callbacks are invoked as
necessary, if they are provided.

---

_See also_:

- The documentation for [command]
- The documentation for [Readline]

## Input callbacks

Below you'll see a list of callbacks that inputs can provide. All callbacks are
optional. All of the callbacks receive the input itself as the first parameter,
which allows for inputs to be constructed as objects.

### should_complete (input, readline)

Called when determining whether the Readline should try to offer completions or
not. `readline` is the [Readline] instance.

### complete (input, text, readline)

Called when completion is attempted in the Readline. `text` is the current text
in the Readline, which is being completed. `readline` is the
[Readline] instance. The callback can return two values:

- `completions`: A list of completions
- `options`: A table of option associated with the completions. Possible keys
are:
  * `title`: The title to set for the Readline when displaying the completions
  * `caption`: A textual caption to display before the list of completions
  * `list`: A table of options to set for the underlying [List] instance used
for displaying the completions

__Example:__

```moonscript
input = complete: -> {'one', 'two' }
howl.app.window.readline\read 'Complete: ', input

input = complete: -> { 1, 2 }, { title: 'My completions' }
howl.app.window.readline\read 'Complete: ', input
```

When pressing tab to complete for the first example, you'll be presented with a
completion list showing "one" and "two". Choosing one of these will return the
chosen string.

The second example is similar, but shows two additional things:

- The use of the `title` option cause the Readline title to display "My
completions" as the completions are shown.

- The use of non-string completion items. In this case the numbers are converted
to strings before displaying. Choosing one of these from the completion list
will cause the chosen number to be returned from the read(), as a number.


### update (input, text, readline)

Called whenever the text in the Readline changes. `text` is the current text in
the Readline, which is being completed. `readline` is the
[Readline] instance.

### on_completed (input, item, readline)

Called when the user has selected an item from the completion list. `item` is
the selected item, and `readline` is the Readline instance. The default
behaviour of the Readline after a completion has been accepted is to interpret
it as a submit. However, if the *on_completed* callback returns `false`, the
accept is considered as handled and further processing halted.

### on_submit (input, value, readline)

Called when the user submits the content in the Readline, either by accepting a
completion, or by submitting the current text. `value` is the submitted value,
which is either the text currently in the Readline, or the selected item from a
completion list. The callback can return `false` to halt further processing of
the submit, in which case the Readline stays open.

### value_for (input, value)

Called as the final step in the readline processing, after a value has been
submitted, to convert the submit value into the correct return type. `value` is
the submitted value, which is either the text currently in the Readline, or the
selected item from a completion list.

__Example:__ An input that returns the Lua evaluation of the entered text:

```lua
local eval_input = {
  value_for = function(input, value)
    return load('return ' .. value)()
  end
}
return howl.app.window.readline:read('Eval: ', eval_input)
```

Entering "38 + 4" into the Readline and pressing `enter` now causes 42 to be
returned.

### close_on_cancel (readline)

Called when determining whether the Readline should hide if the cancels when in
a completion list. The default behaviour is to close the completion list but
keep the Readline open.

## Functions

### register (name, factory)

Register a new input with name `name`. `factory` is a callable object that
should return a new instance of the input when invoked.

### unregister (name)

Unregisters the input with name `name`.

[command]: command.html
[Readline]: ui/readline.html