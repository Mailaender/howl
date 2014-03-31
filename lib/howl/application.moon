-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'

import Window, Editor, theme from howl.ui
import Buffer, Settings, mode, bundle, bindings, keymap, signal, inputs, timer, clipboard from howl
import File from howl.fs
import PropertyObject from howl.aux.moon
Gtk = require 'ljglibs.gtk'

append = table.insert

sort_buffers = (buffers) ->
  table.sort buffers, (a, b) ->
    return true if a.showing and not b.showing
    return false if b.showing and not a.showing
    ls_a = a.last_shown or 0
    ls_b = b.last_shown or 0
    return ls_a > ls_b if ls_a != ls_b
    a.title < b.title

class Application extends PropertyObject
  title: 'Howl'

  new: (@root_dir, @args) =>
    @windows = {}
    @_editors = {}
    @_buffers = {}
    bundle.dirs = { @root_dir / 'bundles' }
    @_load_base!
    bindings.push keymap
    @window = nil
    @editor = nil
    super!

  @property buffers: get: =>
    buffers = { table.unpack @_buffers }
    sort_buffers buffers
    buffers

  @property editors: get: => @_editors

  @property next_buffer: get: =>
    return @new_buffer! if #@_buffers == 0

    sort_buffers @_buffers
    hidden_buffers = [b for b in *@_buffers when not b.showing]
    return #hidden_buffers > 0 and hidden_buffers[1] or @_buffers[1]

  new_window: (properties = {}) =>
    props = title: @title
    props[k] = v for k, v in pairs(properties)
    window = Window props
    window\set_default_size 800, 640

    window\on_delete_event ->
      return false if @_ignore_modified_on_close
      if #@windows == 1
        modified = [b for b in *@_buffers when b.modified]
        if #modified > 0
          -- postpone the quit check, since we really need to prevent
          -- the close right away by returning true
          timer.asap -> @quit!
        else
          @quit!

        true

    window\on_destroy (window) ->
      for k, win in ipairs @windows
        if win\to_gobject! == window
          @windows[k] = nil

    @g_app\add_window window\to_gobject!

    append @windows, window
    @window = window if #@windows == 1
    window

  new_editor: (opts = {}) =>
    editor = Editor opts.buffer or @next_buffer
    (opts.window or @window)\add_view editor, opts.placement or 'right_of'
    append @_editors, editor
    editor\grab_focus!
    editor

  new_buffer: (buffer_mode) =>
    buffer_mode or= mode.by_name 'default'
    buffer = Buffer buffer_mode
    append @_buffers, buffer
    buffer

  add_buffer: (buffer, show = true) =>
    append @_buffers, buffer
    if show
      @editor.buffer = buffer
      @editor

  close_buffer: (buffer, force = false) =>
    if not force and buffer.modified
      input = inputs.yes_or_no false
      wants_close = @window.readline\read "Buffer '#{buffer}' is modified, close anyway? ", input
      return unless wants_close

    @_buffers = [b for b in *@_buffers when b != buffer]

    if buffer.showing
      for editor in *@editors
        if editor.buffer == buffer
          editor.buffer = @next_buffer

    buffer\destroy!

  open_file: (file, editor = @editor) =>
    for b in *@buffers
      if b.file == file
        editor.buffer = b
        return b

    buffer = @new_buffer mode.for_file file
    status, err = pcall ->
      buffer.file = file
      if editor
        editor.buffer = buffer
      else
        editor = @new_editor buffer

    if not status
      @close_buffer buffer
      log.error "Failed to open #{file}: #{err}"
      nil
    else
      signal.emit 'file-opened', :file, :buffer
      buffer

  save_all: =>
    for b in *@buffers
      if b.modified
        unless b.file
          log.error "No file associated with modified buffer '#{b}'"
          return false

        b\save!

    true

  synchronize: =>
    clipboard.synchronize!

    reload_count = 0
    changed_count = 0

    for b in *@_buffers
      if b.modified_on_disk
        changed_count += 1
        unless b.modified
          b\reload!
          reload_count += 1

    if changed_count > 0
      msg = "Files modified on disk: #{reload_count} buffer(s) reloaded"
      stale_count = changed_count - reload_count
      if stale_count > 0
        log.warn "#{msg}, #{stale_count} modified buffer(s) left"
      else
        log.info msg

  run: =>
    @g_app = Gtk.Application 'io.howl.Editor', Gtk.Application.HANDLES_OPEN
    @g_app\on_activate -> @_load!
    @g_app\on_open (_, files) -> @_load [File(path) for path in *files]

    -- by default we'll not open files in the same instance,
    -- but this can be toggled via the --reuse command line parameter
    args = @args
    if not @args.reuse
      @g_app\register!
      @_load [File(path) for path in *args[2,]]
      args = { args[1] }
      signal.connect 'window-focused', self\synchronize
      signal.connect 'editor-destroyed', (args) ->
        @_editors =  [e for e in *@_editors when e != args.editor]

    @g_app\run args

  quit: (force = false) =>
    if force or not @_should_abort_quit!
      @_on_quit!
      win\destroy! for win in * moon.copy @windows

  save_session: =>
    session = {
      version: 1
      buffers: {}
      window: {
        maximized: @window.maximized
        fullscreen: @window.fullscreen
      }
    }

    for b in *@buffers
      continue unless b.file
      append session.buffers, {
        file: b.file.path
        last_shown: b.last_shown
        properties: b.properties
      }

    @settings\save_system 'session', session

  _load: (files = {}) =>
    local window
    unless @_loaded
      @settings = Settings!
      @_load_core!
      bundle.load_all!
      @settings\load_user!
      theme.apply!
      @_load_application_icon!

      signal.connect 'mode-registered', self\_on_mode_registered
      signal.connect 'mode-unregistered', self\_on_mode_unregistered
      signal.connect 'buffer-saved', self\_on_buffer_saved
      signal.connect 'key-press', (args) -> howl.editing.auto_pair.handle args.event, @editor

      window = @new_window!
      @_set_initial_status window

    if #files > 0
      @open_file(File(path)) for path in *files

    unless @_loaded
      @_restore_session window, #files == 0

    if #@editors == 0
      @new_editor @_buffers[1] or @new_buffer!

    window\show_all! if window
    @_loaded = true

  _should_abort_quit: =>
    return if @_ignore_modified_on_close

    modified = [b for b in *@_buffers when b.modified]
    if #modified > 0
      input = inputs.yes_or_no false
      wants_close = @window.readline\read "Modified buffers exist, close anyway? ", input
      return true unless wants_close
      @_ignore_modified_on_close = true
      @window\destroy!
      true

  _on_quit: =>
    @save_session! unless #@args > 1

  _on_mode_registered: (args) =>
    -- check if any buffers with default_mode could use this new mode
    mode_name = args.name
    default_mode = mode.by_name 'default'
    for buffer in *@_buffers
      if buffer.file and buffer.mode == default_mode
        buffer_mode = mode.for_file buffer.file
        if mode != default_mode
          buffer.mode = buffer_mode

  _on_mode_unregistered: (args) =>
    -- remove the mode from any buffers that are previously using it
    mode_name = args.name
    default_mode = mode.by_name 'default'
    for buffer in *@_buffers
      if buffer.mode.name == mode_name
        if buffer.file
          buffer.mode = mode.for_file buffer.file
        else
          buffer.mode = default_mode

  _on_buffer_saved: (args) =>
    file = args.buffer.file

    -- automatically update bytecode for howl files
    -- todo: move this away
    if file.extension and file.extension\umatch(r'(lua|moon)') and file\is_below(@root_dir)
      bc_file = File file.path\gsub "#{file.extension}$", 'bc'
      f, err = loadfile file
      if f
        bc_file.contents = string.dump f, false
      else
        bc_file\delete! if bc_file.exists
        log.error "Failed to update byte code for #{file}: #{err}"

  _restore_session: (window, restore_buffers) =>
    session = @settings\load_system 'session'

    if session and session.version == 1
      if restore_buffers
        for entry in *session.buffers
          file = File(entry.file)
          continue unless file.exists
          status, err = pcall ->
            buffer = @new_buffer mode.for_file file
            buffer.file = file
            buffer.last_shown = entry.last_shown
            buffer.properties = entry.properties

          log.error "Failed to load #{file}: #{err}" unless status

      if session.window
        with session.window
          window.maximized = .maximized
          window.fullscreen = .fullscreen

  _set_initial_status: (window) =>
    if log.last_error
      window.status\error log.last_error.message
    else
      window.status\info 'Howl ready.'

  _load_base: =>
    require 'howl.variables.core_variables'
    require 'howl.modes'

  _load_core: =>
    require 'howl.completion.inbuffercompleter'
    require 'howl.completion.api_completer'
    require 'howl.inputs.basic_inputs'
    require 'howl.inputs.projectfile_input'
    require 'howl.inputs.file_input'
    require 'howl.inputs.buffer_input'
    require 'howl.inputs.variable_assignment_input'
    require 'howl.inputs.search_inputs'
    require 'howl.inputs.bundle_inputs'
    require 'howl.inputs.signal_input'
    require 'howl.inputs.input_input'
    require 'howl.inputs.line_input'
    require 'howl.inputs.mode_input'
    require 'howl.inputs.question_inputs'
    require 'howl.commands.file_commands'
    require 'howl.commands.app_commands'
    require 'howl.commands.ui_commands'
    require 'howl.commands.edit_commands'
    require 'howl.editing'

  _load_application_icon: =>
    for dir in *{ @root_dir.parent, @root_dir }
      icon = dir\join('share/icons/hicolor/scalable/apps/howl.svg')
      if icon.exists
        status, err = pcall Gtk.Window.set_default_icon_from_file, icon.path
        log.error "Failed to load application icon: #{err}" unless status
        return

    log.warn "Failed to find application icon"

signal.register 'file-opened',
  description: 'Signaled right after a file was opened in a buffer',
  parameters:
    buffer: 'The buffer that the file was opened into'
    file: 'The file that was opened'

return Application
