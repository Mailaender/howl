---
title: Editing
---

# Editing

## Overview

This section attempts to highlight a few things that you might encounter while
editing, or that might simplify your editing experience.

## Auto pairs

Auto pairs, where a matching end character is inserted automatically as you type
the starting character, is supported out of the box in Howl. This can save you
some typing as you don't have to type out the ending character for every
combination of `[]`, `{}`, etc. Exactly what pairs are enabled for a buffer is
specified by the buffer's mode.

In case you find auto pairs annoying, the configuration variable
`auto_pair` lets you specify whether you want this on or not.

## Code blocks

Code blocks are code snippets that are automatically inserted as you type. They
differ from completions in that they are inserted without any prompting, and can
include more text than a single completion would. As an example, if you were to
type the following Lua, and press enter:

```lua
function foo() -- <- cursor here
```

Howl would automatically insert the matching `end` for you, like so:

```lua
function foo()
  -- <- cursor here
end
```

The configuration variable `auto_format` lets you specify whether you want this on
or not.

## Buffer structure

When editing a larger buffer, it can be challenging to quickly jump to a
specific part of it. The `buffer-structure` command (bound to `alt_s` by
default) can provide you with an outline for the current buffer:

![Buffer structure](/images/doc/buffer-structure.png)

How well this works is depending on the language mode - should the mode not
provide custom support for this a general, indentation-based, structure is
provided.

## Buffer grep

Buffer grep works as an alternative to the regular `search-forward` command for
searching for something in the current buffer. It let's you grep all lines in
the current buffer for a search string and displays all matching lines in
real-time as you type:

![Buffer grep](/images/doc/buffer-grep.png)

This is decidedly less effective than doing a plain search, which can be a
factor for large buffers.

## Comments

The `editor-toggle-comment` is bound to `ctrl_slash` by default, and let's you
quickly comment and uncomment code.

## Word wrapping

Howl provides optional support for hard wrapping of text paragraphs. The
`fill-paragraph` command, bound to `alt_q` by default, will reflow a paragraph
so that each line is at most as long as the configuration variable
`hard_wrap_column` specifies.

You can also turn on automatic reflowing of paragraphs if you like, by
customizing the `auto_reflow_text` configuration variable. This reflow the
current paragraph as you type if needed. For example, the author keeps this in
his `~/.howl/init.moon` to enable automatic reflowing for markdown documents:

```moonscript
howl.mode.configure 'markdown', {
  auto_reflow_text: true
}
```

Unlike most other feature, this is not enabled by default, so you have to
explicitly turn it on.

## Version control diffs

The version control support in Howl is currently rather spartan, and will be
expanded in future releases. However, if you're using Git you might find the
`vc-diff` and `vc-diff-file` commands useful. The former displays a complete
diff for your entire repository, while the latter displays a diff for the
current file.

## Documentation popup

_Support for this is dependent on the language mode, and is currently only
available for Lua and Moonscript._

The `show-doc-at-cursor` command, bound to `ctrl_q` by default, pops up
documentation for the symbol at the cursor if available:

![Show doc](/images/doc/show-doc.png)

---

*Next*: [Using multiple views](views.html)