# harness 0.2.0

Editor bridge and the Windows support from the development line.

* New RStudio addin `send_selection_to_coder()`: it reads the editor selection,
  asks for a short note, and sends the note with a `file:line` reference to the
  coder running in the harness terminal that `launch()` opened. Bind it to a
  keyboard shortcut through Tools, Modify Keyboard Shortcuts, Addins. The addin
  forwards text the user wrote; it does not run an agent loop and does not call a
  language model. It needs no new dependency.
* `launch()` records the terminal it opens, so the addin targets it; when the
  record is stale, the addin finds a harness terminal by its caption.
* Includes the Windows support for binary discovery and terminal launch listed
  under 0.1.1.

# harness 0.1.1

Windows support for binary discovery and terminal launch.

* `find_binary()` searches the Windows install locations (the npm global prefix,
  nvm-windows and fnm node bins, scoop and winget shims) and asks `where`, which
  honours PATHEXT and resolves the `.cmd` and `.exe` shims that `Sys.which()` can
  miss.
* `launch()` opens an external terminal on Windows through Windows Terminal
  (`wt`) or `cmd`, and inside RStudio it uses a Command Prompt terminal with
  Windows-style quoting for the directory change and the coder command.

# harness 0.1.0

First release.

* Launches a command-line coding agent (`claude`, `opencode` or `codex`) in a
  terminal tab pre-configured for one of seventeen professional R roles, with
  curated skills from the external community-skills catalogue, a role system
  prompt, a folder layout and quality gates.
* Audit-first convention: every role pins manual execution. The agent writes
  scripts into the role's layout folders and a per-step decision log under
  `logs/`, and never runs them; the user runs every script.
* Public API: `status()`, `setup()`, `available_roles()`, `role()`,
  `role_list()`, `role_skills()`, `role_config()`, `launch()`, `adapters()`,
  `scaffold_layout()`, `community_skills_path()`, `clone_community_skills()` and
  `update_community_skills()`.
* The community-skills catalogue is an external dependency, discovered at
  runtime and never bundled. The package accesses the network only when the user
  calls `clone_community_skills()` or `update_community_skills()`.
