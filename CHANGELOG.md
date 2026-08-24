# Changelog

The format follows, approximately, Keep a Changelog. Versions follow semantic
versioning. `NEWS.md` carries the same history in the form R users read through
`utils::news()` and the CRAN package page; this file is the repository-facing
copy and is not shipped in the tarball.

## [Unreleased]

Nothing yet.

## [0.2.0]

Dated once the release is published.

### Added

- RStudio addin `send_selection_to_coder()`. It reads the editor selection, asks
  for a short note, and sends the note with a `file:line` reference to the coder
  running in the harness terminal that `launch()` opened. The addin forwards text
  the user wrote; it does not run an agent loop and does not call a language
  model, and it needs no new dependency. It is declared in
  `inst/rstudio/addins.dcf` and is bound to a keyboard shortcut by the user.
- Session registry: `launch()` records the terminal it opens so the addin can
  target it. When the record is stale, the addin finds a harness terminal by its
  `harness:<adapter>:<role>` caption.

## [0.1.1]

Folded into the 0.2.0 release rather than published on its own.

### Added

- Windows support in `find_binary()`: the npm global prefix, the nvm-windows and
  fnm node bins, and the scoop and winget shims are searched, followed by a
  `where` probe, which honours PATHEXT and resolves the `.cmd` and `.exe` shims
  that `Sys.which()` can miss.
- Windows support in `launch()`: an external terminal is opened through Windows
  Terminal (`wt`) or `cmd`, and inside RStudio a Command Prompt terminal is used,
  with Windows quoting for the directory change and the coder command.

### Fixed

- Skill linking falls back to `Sys.junction()` when `file.symlink()` fails, since
  symlink creation on Windows needs a privilege most accounts lack.

## [0.1.0] - 2026-06-09

First CRAN release.

### Added

- Launch of a command-line coding agent (`claude`, `opencode` or `codex`) in a
  terminal tab pre-configured for one of seventeen professional R roles, with
  curated skills from the external community-skills catalogue, a role system
  prompt, a folder layout and quality gates.
- Harness loader and validator reading `inst/harness/<role>.yml` against a fixed
  schema. The manual execution policy is structural: a harness that does not
  declare `execution_policy: manual` is rejected at load time.
- Audit-first convention. The agent writes scripts into the role's layout folders
  and a per-step decision log under `logs/`, and runs nothing; the user runs every
  script. The convention is added centrally to the prompt body and to every
  layout, so it reaches roles contributed later without each YAML declaring it.
- Public API: `status()`, `setup()`, `available_roles()`, `role()`, `role_list()`,
  `role_skills()`, `role_config()`, `launch()`, `adapters()`, `scaffold_layout()`,
  `community_skills_path()`, `clone_community_skills()` and
  `update_community_skills()`.
- Adapter registry isolating each coder behind `find_binary()`, `build_config()`
  and `terminal_command()`, with the linking, the prompt body and the AGENTS.md
  convention shared across adapters. Adapters write configuration and link skills;
  `launch()` owns the terminal.
- Discovery of the community-skills catalogue through `COMMUNITY_SKILLS_PATH`,
  `~/.community-skills/` or `~/projects/community-skills/`. The catalogue is an
  external dependency and is never bundled. The package accesses the network only
  when the user calls `clone_community_skills()` or `update_community_skills()`;
  load-time auto-update is opt-in through the `harness.auto_update` option or the
  `HARNESS_AUTO_UPDATE` environment variable.
- Coder binary discovery that resolves npm-global and node version-manager bins
  (nvm, fnm) and falls back to a login or interactive shell probe, so adapters are
  found under the trimmed PATH of an RStudio session. Discovered paths are not
  symlink-resolved, so launcher shims are preserved.
- testthat suite covering the harness schema, the adapters, the launch path and
  the environment discovery, against fixture checkouts and without contacting a
  real coder binary.

### Fixed

- Adapters write no package-specific block into the coder's own configuration.
  opencode validates `opencode.json` against its schema and rejects unknown keys;
  the opencode config now carries only valid keys (`$schema` and `instructions`)
  and preserves existing user keys. The claude adapter does not modify
  `settings.json`, since the coder needs nothing there and rewriting a user's
  global settings risks disturbing unrelated configuration. The codex adapter
  writes no config file with package-specific keys.
