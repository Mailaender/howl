---
title: howl.io.Process
---

# howl.io.Process

## Overview

The Lua runtime itself only provides rudimentary support for running processes,
in the form of
[os.execute](http://www.lua.org/manual/5.2/manual.html#pdf-os.execute) and
[io.popen](http://www.lua.org/manual/5.2/manual.html#pdf-io.popen). Apart from
not providing any way of more advanced interaction with the process, such as
sending signals, the above both suffer from the flaw of blocking program
execution. In the context of an interactive application, such as Howl, this is
unacceptable is it means the application will be unresponsive while waiting for
command termination or output. The howl.io.Process module provides a way of
launching and interacting with external processses that, while still providing
the appearance and ease of use of a synchronous API, is fully asynchrounous and
ensures Howl remains responsive.

_See also_:

- The [spec](../../spec/io/process_spec.html) for Process

## Properties

### argv

The argument list that was used to launch the process.

### exited

True if the process has terminated, normally or not, and false otherwise.

### exited_normally

True if the process terminated normally, i.e. due to an explicit exit or a
return from `main`, and false otherwise. Only available once the process has
exited ([exited](#exited) is true).

### exit_status

The exit status of the process. Only available if the process has exited
normally ([exited_normally](#exited_normally) is true).

### pid

The process id of the process.

### signal

Holds the signal that caused the process to terminate. Only available if the
process was indeed terminated due to a signal ([signalled](#signalled) is true).

### signalled

True if the process was terminated as the result of a signal. Only available
once the process has exited ([exited](#exited) is true).

### signal_name

A string representation of the signal that caused the process to terminate. Only
available if the process was indeed terminated due to a signal
([signalled](#signalled) is true).

### stderr

An [InputStream] instance that can be used for reading the process' error
output. The process must have been created with the `read_stderr` option for
this field to be available.

### stdin

An [OutputStream] instance that can be used for writing to the process' input.
The process must have been created with the `write_stdin` option for this field
to be available.

### stdout

An [InputStream] instance that can be used for reading the process' standard
out. The process must have been created with the `read_stdout` option for this
field to be available.

### successful

True if the process exited normally, with an exit code of zero. Only available
once the process has exited ([exited](#exited) is true).

## Functions

### Process(options)

Launches a new process with the specified options. `options`, a table, can
contain the following fields:

- `cmd`: _[required]_ The command to run. This can be either a string, in which
case it's parsed as a shell command, or a table comprising the full command line
invocation. Note that since Howl is not a shell, shell specific expansions are
not supported, but will instead be passed verbatim as is.

- `read_stdout`: _[optional]_ When specified, a pipe will be opened for the
process' standard out, and the [stdout](#stdout) field will be available for
reading the process' output.

- `read_stderr`: _[optional]_ When specified, a pipe will be opened for the
process' error out, and the [stderr](#stderr) field will be available for
reading the process' error output.

- `write_stdin`: _[optional]_ When specified, a pipe will be opened for the
process' input, and the [stdin](#stdin) field will be available for writing to
the process' input.

- `working_directory`: _[optional]_ The path to set as the process' working
directory.

- `env`: _[optional]_ A table of keys and values that will be used as the
process' environment.

An error will be raised if the specified command could not be started. Otherwise
a process object is returned for the started command.

## Methods

### send_signal (signal)

Sends `signal` to the process. `signal` can be either a number or a string
representation of the signal, such as `HUP`, `KILL`, etc.

### wait ()

Waits for the process to terminate.

[InputStream]: input_stream.html
[OuputStream]: output_stream.html