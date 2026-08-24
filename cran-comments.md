## Submission

This is an update of a CRAN package (0.1.0 to 0.2.0). It adds an RStudio addin,
`send_selection_to_coder()`, that forwards the editor selection with a file:line
reference to the coder running in the harness terminal, and it folds in the
Windows support for binary discovery and terminal launch from the development
line. The addin forwards text the user wrote; it does not run an agent loop and
does not call a language model. There are no removals from the public API.

## Test environments

- local: Ubuntu 24.04, R 4.6.1
- GitHub Actions: ubuntu-latest, macos-latest, windows-latest (R release)
- win-builder: R-release 4.6.1 and R-devel (2026-08-22 r90443), both Windows

## R CMD check results

0 errors | 0 warnings | 0 notes.

Both win-builder runs report `Status: OK`. The local check adds one note only
because HTML Tidy is absent on that machine, so the HTML validation step is
skipped; it does not reflect the package.

## Notes for the CRAN team

- The package is a pure-R bootstrapper for command-line coding agents. It does
  not run a language model and does not access the network when loaded. The
  startup hook only prints a message; it performs no network or filesystem
  action.
- Functions that write to the user's filesystem (`setup()`,
  `scaffold_layout()`, `launch()`) or access the network
  (`clone_community_skills()`, `update_community_skills()`) act only when the
  user calls them. Load-time auto-update of the external catalogue is off by
  default and runs only under an explicit opt-in.
- The curated skills come from an external repository (community-skills) that is
  discovered at runtime and is not bundled, so the tarball stays small.
- Examples that require an external coder binary, or that would write outside a
  temporary directory, are wrapped in `\dontrun{}`.
