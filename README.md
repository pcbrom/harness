[![R-CMD-check](https://github.com/pcbrom/harness/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pcbrom/harness/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# harness

<!-- badges: start -->
<!-- badges: end -->

`harness` launches a command-line coding agent of your choice in a terminal tab
pre-configured for a professional R role. A role is described by a curated
harness: a subset of community skills, a system prompt, a folder layout, and
quality gates.

The package does not run an agent loop and does not call a language model. It
discovers the chosen coder binary, generates its configuration, links the
curated skills, and opens the terminal. Code written by the agent is run
manually by the user, so that every generated script passes through a human
audit gate before execution.

This is the second package of the `r-cs-packages` family, after
[gpumetropolis](https://github.com/pcbrom/gpumetropolis).

## Installation

The development version can be installed from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("pcbrom/harness")
```

## External dependency: community-skills

The curated skills come from the external
[community-skills](https://github.com/pcbrom/community-skills) catalogue, which
is never bundled with this package. Clone it and make it discoverable through
the `COMMUNITY_SKILLS_PATH` environment variable, `~/.community-skills/` or
`~/projects/community-skills/`.

## Usage

``` r
library(harness)

# Inspect the environment: skills checkout, roles, adapters
status()

# List the curated roles
available_roles()

# Validate the environment for a role and scaffold its folder layout
setup("data-scientist", scaffold = TRUE)

# Launch the chosen coder in a terminal tab, configured for the role
launch("claude", role = "data-scientist")
```

`launch()` opens the terminal with `rstudioapi::terminalCreate` when run inside
RStudio, and falls back to an external terminal emulator or, when none is
available, reports the command for the user to run.

## Roles in this version

Four curated harnesses ship in the current development version:
`data-scientist`, `statistician`, `package-maintainer` and `paper-author`. The
target taxonomy covers seventeen professional roles; the remaining roles and
four further coder adapters arrive in later development phases.

## Audit-first convention

Every harness pins `execution_policy: manual`. The package rejects, at load
time, any harness that does not. The system prompt of each role instructs the
agent to write scripts into the role's layout folders and to leave execution to
the user. The agent writes, the user runs.

## License

MIT, see [LICENSE](LICENSE).
