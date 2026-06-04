## Submission

This is a new submission.

## Test environments

- local: Ubuntu 24.04, R 4.6.0
- win-builder: R-devel and R-release (Windows)

## R CMD check results

0 errors | 0 warnings | 1 note.

The note is "New submission", which is expected for a first submission to CRAN.
There is no other note, warning or error.

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
