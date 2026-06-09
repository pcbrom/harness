# Roadmap

This roadmap records the planned work after the 0.1.0 CRAN release. The items
are specified so that a contributor can pick one up and finish it. Dates are not
fixed; the order reflects priority.

## 0.1.1: Windows support for binary discovery and terminal launch

The 0.1.0 binary discovery and terminal launch are tuned for Linux and macOS.
The package loads and passes R CMD check on Windows (confirmed on the CRAN
Windows flavor and on win-builder), but the discovery and the external-terminal
launch are written for Unix. This release closes the Windows gap. macOS is
already compatible; the work is specific to Windows.

- `find_binary`: add the Windows install locations to the candidate paths (the
  npm global prefix under `%APPDATA%\npm`, the nvm-windows and fnm node bins,
  scoop and winget shims), and add a Windows probe analogous to the login-shell
  probe, using `where` or PowerShell `Get-Command`. Today the login-shell probe
  is guarded to Unix only.
- `find_terminal_emulator` and `spawn_external`: add a Windows branch. Open the
  coder in Windows Terminal (`wt`) when present, falling back to `cmd /c start`.
  The current external-terminal path uses `bash -lc`, which is Unix only.
- `spawn_terminal`: the `cd` sent to the RStudio terminal uses sh-style quoting.
  Detect the terminal shell and use `shQuote(type = "cmd")` for cmd or
  PowerShell, keeping sh quoting for a bash terminal.
- CI: add a discovery smoke test on the `windows-latest` runner of the existing
  GitHub Actions workflow.

## 0.2.0: editor bridge (RStudio addin)

An RStudio addin that sends the editor selection to the coder running in the
harness terminal tab. It does not run an agent loop and does not call a language
model; it forwards text the user wrote, so it stays within the audit-first
design.

Scope: RStudio only, shipped inside this package, with no companion package.

- Addin: declare it in `inst/rstudio/addins.dcf`, bindable to a keyboard shortcut
  by the user. The addin function lives in `R/`.
- Selection: read the editor selection and its file and line range with
  `rstudioapi::getSourceEditorContext()`.
- Annotation box: the minimum viable form is a single-line note via
  `rstudioapi::showPrompt`, which adds no dependency (rstudioapi is already in
  Suggests). A multi-line gadget with `miniUI` and `shiny` can follow, behind
  `requireNamespace`, in Suggests.
- Submit: send the composed message (the annotation and a file:line reference, or
  the selection) to the harness terminal with `rstudioapi::terminalSend`. The
  terminal is the one `launch()` opened, tracked by its id or found by the
  caption `harness:<adapter>:<role>`.
- Session registry: to target the terminal, `launch()` records the terminal id
  it created.

Caveat: interactive coder TUIs treat Enter as submit, so a multi-line block with
embedded newlines submits at the first line. Ship the one-line form first (the
annotation plus a file:line reference); treat pasting a multi-line block as
experimental, depending on bracketed paste, or route it through a
`.harness/inbox/` file and send a reference.

## Backlog (no fixed version)

- Adapters `aider` and `gemini-cli`, to complete the five coders planned for the
  line. Each is an R file in `R/adapter_<coder>.R` exposing `find_binary`,
  `build_config` and `terminal_command`, following the claude, opencode and codex
  adapters.
- `sessions()` indexer: list the session logs under `logs/` (or the role's
  equivalent), reading the decision-log files.
- Vignettes: getting-started, harness-anatomy, audit-first-workflow and
  adding-a-harness.
