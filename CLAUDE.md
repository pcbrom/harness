# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this package is

`harness` is a pure-R bootstrapper (CRAN, MIT, `pcbrom/harness`). It launches a
command-line coding agent (`claude`, `opencode`, `codex`) in a terminal tab
pre-configured for one of seventeen professional R roles. It does not run an
agent loop, does not call a language model, and does not execute code the agent
writes.

## Binding invariants

These three constraints define the product. Changing any of them is a decision
for the author, not a refactor.

1. **No agent loop, no LLM call inside the package.** All conversation happens in
   the external coder. The package discovers a binary, writes configuration,
   links skills, and opens a terminal. `send_selection_to_coder()` forwards text
   the user wrote and stays inside this line.
2. **Manual execution of generated code.** Enforced structurally, not by
   convention: `validate_harness()` in [R/harness.R](R/harness.R) rejects any
   role whose `execution_policy` is not `manual`, and `harness_prompt_body()` in
   [R/adapters.R](R/adapters.R) appends the policy to every role prompt for every
   adapter.
3. **`community-skills` is an external dependency, never bundled.** It is
   discovered at runtime from `COMMUNITY_SKILLS_PATH`, `~/.community-skills/` or
   `~/projects/community-skills/` (see `community_skills_candidates()` in
   [R/setup.R](R/setup.R)). Nothing from the catalogue enters the tarball.

Two further rules hold in practice: the package writes to the filesystem and
touches the network only when the user calls a function (the `.onAttach` hook in
[R/zzz.R](R/zzz.R) only prints, and load-time catalogue update is opt-in through
`harness.auto_update` / `HARNESS_AUTO_UPDATE`); and no adapter ever overwrites a
user file. `AGENTS.md`, `.claude/CLAUDE.md` and existing skill links are written
only when absent, otherwise the prompt is diverted to a role-specific file and
an occupied link destination is reported as a conflict.

## Commands

```r
devtools::load_all(".")            # interactive development
devtools::test()                   # full testthat suite
devtools::test(filter = "harness") # one file: tests/testthat/test-harness.R
testthat::test_file("tests/testthat/test-launch.R")
devtools::document()               # roxygen2 -> man/ and NAMESPACE
devtools::check()                  # R CMD check
```

```bash
R CMD build . && R CMD check --as-cran harness_*.tar.gz
```

The suite is offline and hermetic. Tests never call a real coder binary and never
touch a real checkout: [tests/testthat/helper-fixtures.R](tests/testthat/helper-fixtures.R)
builds throwaway `community-skills` checkouts and project directories with
`withr::local_tempdir()`, and adapter tests drive `build_config()` through the
`config_home`, `skills_path` and `binary` overrides of `launch()`. Keep new tests
in that style; a test that reaches the network or the user's `~/.claude` is a
defect.

CI runs `R CMD check` on ubuntu, macos and windows latest, R release
([.github/workflows/R-CMD-check.yaml](.github/workflows/R-CMD-check.yaml)).

## Architecture

The flow is a straight pipeline, and each stage lives in one file.

**Catalogue.** [inst/harness/](inst/harness/) holds one YAML per role. Required
keys: `name`, `version`, `description`, `skills`, `system_prompt`, `layout`,
`execution_policy`. Optional: `quality_gates`, `deps_check`, `optional_deps`,
`adapter_overrides`. [R/harness.R](R/harness.R) reads, normalises and validates
them; `read_harness_yaml()` injects a `logs` entry into every role's layout, so
the decision-log convention reaches roles contributed later without each YAML
declaring it.

**Role object.** `role(name)` returns a `harness_role` (a plain list with the
source path in an attribute). `available_roles()`, `role_list()`, `role_skills()`
and `role_config()` are introspection over the same catalogue.

**Adapters.** Each coder is isolated behind three functions returned by
`adapter_<coder>()`:

```
find_binary()                             -> path or NA_character_
build_config(harness, project_dir, opts)  -> list describing what it wrote
terminal_command(config, opts)            -> list(command, args, workdir)
```

`build_config()` writes configuration and links skills but never spawns a
process; `launch()` owns the terminal. Registration is a single entry in
`adapter_registry()` in [R/adapters.R](R/adapters.R). What differs per coder is
only where the prompt goes and where skills are read from: claude uses
`~/.claude/skills/` plus the project `.claude/CLAUDE.md`; opencode uses
`.opencode/skills/`, `AGENTS.md` and a schema-validated `opencode.json` (only
valid keys, no package-specific block); codex uses `.codex/skills/` and
`AGENTS.md`. The shared parts, `harness_link_skills()`, `harness_prompt_body()`
and `harness_write_agents()`, stay in [R/adapters.R](R/adapters.R).

**Skill linking.** Symlinks from the checkout into the coder's skills root, with
`Sys.junction()` as the Windows fallback because `file.symlink()` needs a
privilege most Windows accounts lack. Outcomes are partitioned into `linked`,
`missing` (no `SKILL.md` in the checkout) and `conflict` (destination occupied by
something else, never overwritten).

**Launch.** [R/launch.R](R/launch.R) scaffolds the layout, builds the config,
then opens a terminal: `rstudioapi::terminalCreate` inside RStudio (with a
`win-cmd` shell and cmd quoting on Windows), an external emulator otherwise, and
as a last resort it prints the command for the user to run. `dry_run = TRUE`
stops after configuration and is the seam the tests use.

**Session registry and editor bridge.** `launch()` records the terminal it
created in the package-local environment of [R/session.R](R/session.R), keyed by
the caption `harness:<adapter>:<role>`. `send_selection_to_coder()`
([R/editor_bridge.R](R/editor_bridge.R)) targets that terminal, falling back to a
caption scan when the record is stale. The message is deliberately one line
(note plus `file:start-end`), because interactive coder TUIs submit at the first
newline.

**Binary discovery.** [R/utils.R](R/utils.R) is more involved than it looks and
for a reason: R under RStudio inherits a trimmed PATH that omits npm-global and
node version-manager bins. Discovery tries `Sys.which()`, then conventional
install roots including nvm and fnm globs, then probes the user's shell with both
`-lc` and `-ic` under a `timeout`. Discovered paths are returned unresolved:
launcher shims must be invoked through the shim, not through the script they
point at.

## Conventions when editing

- Errors go through `harness_abort(message, class = ...)`, which tags conditions
  with a specific class plus `harness_error`. Tests match on the class, so a new
  failure mode gets a new class rather than a bare `stop()`.
- `%||%` is defined in [R/harness-package.R](R/harness-package.R) and treats
  zero-length as missing, not only `NULL`.
- Code comments are English, and they explain the non-obvious constraint (why a
  junction on Windows, why the shim is not resolved) rather than restating the
  call.
- Run `devtools::document()` after touching roxygen blocks; `man/` and `NAMESPACE`
  are generated and committed.
- Adding a role: one YAML in `inst/harness/`, skills drawn exclusively from
  `community-skills` (the package ships no `SKILL.md` of its own), and the system
  prompt must restate manual execution in the role's own terms.
- Adding an adapter: one `R/adapter_<coder>.R` following the claude adapter, one
  line in `adapter_registry()`, tests against a fixture checkout. `aider` and
  `gemini-cli` are the two open ones ([ROADMAP.md](ROADMAP.md)).
- Non-standard top-level files must be listed in `.Rbuildignore`, or
  `R CMD check` reports them.

## Documentation style

Public artefacts (README, NEWS, roxygen, cran-comments) are formal, third person
and factual. No em-dash, no emoji, and no filler intensifiers (crucial,
essential, fundamental, revolutionary). Every claim about behaviour must be true
of the code as written.

## Release cycle

The package ships on its own CRAN cycle, independent of `community-skills`.
Release artefacts: [NEWS.md](NEWS.md) (one section per version),
[cran-comments.md](cran-comments.md) (submission note, test environments, check
results, notes for the CRAN team), `CRAN-SUBMISSION`, `.zenodo.json` for the DOI
deposit, and a git tag. Distribution channels are CRAN, r-universe
(`pcbrom.r-universe.dev`) and Zenodo.

0.1.0 is on CRAN. 0.2.0 (editor bridge plus the Windows hardening from 0.1.1) is
the release in flight, with single authorship. A submission is never routine:
run `devtools::submit_cran()`, push a tag, or `git push` to the remote only when
the author asks for that specific step.

`BRIEFING.md` at the root is a local, unversioned state file (listed in
`.gitignore` and `.Rbuildignore`); read it for the current phase and for closed
decisions, and do not stage it.
