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

## Why use it

For several years the most capable agentic coding tools reached R users first
as dedicated editors or as extensions for general-purpose IDEs. That path moved
part of the R workflow out of RStudio, into an environment built around other
languages. `harness` reverses the move. Modern command-line coding agents are
editor-agnostic: they run in any terminal, including the RStudio terminal tab.
The package wires them there, anchored in the project directory, while the
console, the plots, the environment pane and the data viewer stay where the R
user already works. The agentic session and the analytical session share one
window again.

Three properties separate this from opening a coder in a bare terminal:

- Role curation. Instead of a generic chat, the agent receives the subset of
  community skills, the system prompt and the folder layout that fit a
  professional role, so its output matches the task. A statistician and a
  package maintainer get different skills, different conventions and different
  output folders from the same command.
- Audit-first execution. The agent writes scripts into the role's layout folders
  and never runs them. The user runs every script from the console with
  `source()`. The human gate is the design, not a restriction: nothing the agent
  produces reaches the session state until a person reads it and chooses to run
  it.
- One configuration, many coders. The same role drives any supported coder
  through its adapter. Switching from one command-line agent to another does not
  change the role, the skills or the folder convention; only the launch command
  changes.

The case for staying in RStudio is therefore concrete rather than nostalgic: the
R-native environment hosts the agent in-place, adds role-aware curation that a
generic terminal session lacks, and enforces a review step before execution. The
package competes with neither RStudio's own assistants nor the command-line
coders it launches; it positions the agent inside the R workflow and curates it
for the work at hand.

## Installation

The development version can be installed from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("pcbrom/harness")
```

## External dependency: community-skills

The curated skills come from the external
[community-skills](https://github.com/pcbrom/community-skills) catalogue, which
is never bundled with this package. When the catalogue is not found, the package
points at the command that fetches it as soon as it is loaded:

``` r
library(harness)
#> harness: community-skills catalogue not found.
#>   Fetch it with:  harness::clone_community_skills()
#>   Or set COMMUNITY_SKILLS_PATH to an existing checkout.
```

`clone_community_skills()` clones the catalogue into `~/.community-skills/`, one
of the discovery paths, so the next call finds it with no further configuration:

``` r
clone_community_skills()
```

To use a checkout you already keep elsewhere, point the environment variable at
it instead of cloning, through `COMMUNITY_SKILLS_PATH`, `~/.community-skills/` or
`~/projects/community-skills/`.

### Keeping the catalogue current

`update_community_skills()` runs a fast-forward `git pull` on the checkout so
the curated skills track upstream:

``` r
update_community_skills()
```

The update can also run when the package is attached, but only as an explicit
opt-in. The default does nothing on load, so the package never accesses the
network without instruction. Enable the behaviour with an option or an
environment variable:

``` r
options(harness.auto_update = TRUE)   # in .Rprofile, for example
# or
Sys.setenv(HARNESS_AUTO_UPDATE = "true")
library(harness)
#> harness: community-skills updated at /home/you/.community-skills.
```

## Usage

``` r
library(harness)

# Inspect the environment: skills checkout, roles, adapters
status()

# List the curated roles, names only
available_roles()

# Tabulate the roles with version, skill count and description
role_list()

# Inspect the skills of a role
role("data-scientist")$skills
role_skills("data-scientist")

# Skills of a role, flagged by presence in the community-skills checkout
role_skills("data-scientist", available = TRUE)

# Show the full harness configuration of a role, including the system prompt
role_config("data-scientist")

# Validate the environment for a role and scaffold its folder layout
setup("data-scientist", scaffold = TRUE)

# Launch the chosen coder in a terminal tab, configured for the role
launch("claude", role = "data-scientist")
```

`launch()` opens the terminal with `rstudioapi::terminalCreate` when run inside
RStudio, and falls back to an external terminal emulator or, when none is
available, reports the command for the user to run.

### Function reference

| Function | Purpose |
|---|---|
| `status()` | report the environment: checkout, roles, adapters |
| `available_roles()` | role names |
| `role_list()` | roles with version, skill count and description |
| `role_skills(name, available =)` | skills of a role, optionally flagged by checkout presence |
| `role(name)` | load the full role object |
| `role_config(name)` | print the full configuration, including the system prompt |
| `setup(name, scaffold =)` | validate the environment and scaffold the layout |
| `launch(adapter, role, ...)` | open the coder in a terminal tab |
| `adapters()` | registered coder names |
| `clone_community_skills()` | fetch the external catalogue |
| `update_community_skills()` | fast-forward the catalogue |

## A first session

Set up a role and launch a coder:

``` r
library(harness)
setup("data-scientist", scaffold = TRUE)   # validate and create the layout
launch("claude", role = "data-scientist")  # open the coder in a terminal tab
```

In the coder terminal, state a concrete task, for example: classify the species
in the iris dataset, with an exploratory figure, a stratified train/test split,
a multinomial model and the test-set accuracy.

The agent writes, but does not run, a script under `analysis/scripts/` and a
decision log under `logs/`:

```
analysis/scripts/2026-06-04_iris-classification.R
logs/2026-06-04_01_iris-classification.md
```

The log records the decision, its justification and the result, leaving the run
outcome blank until execution. You read the script, then run it yourself:

``` r
source("analysis/scripts/2026-06-04_iris-classification.R")
#> Test accuracy: 0.911
```

Nothing the agent produced reached the session state until you chose to run it.

## Adapters

The coder is selected by the first argument of `launch()`. The current adapters
are `claude`, `opencode` and `codex`; `aider` and `gemini-cli` arrive in a later
phase. The same role drives any adapter, so switching coder keeps the skills,
the prompt and the folder convention:

``` r
launch("opencode", role = "data-scientist")
launch("codex", role = "data-scientist")
```

To experiment without touching a real coder configuration, redirect the config
home to a temporary directory:

``` r
launch("opencode", role = "data-scientist", config_home = tempfile("opencode-home"))
launch("codex", role = "data-scientist", config_home = tempfile("codex-home"))
```

### Comparing coders on the same task

Because the same role drives any coder, a single project can run several coders
on one problem and keep their outputs apart. Scaffold the role once, then open
each coder and give it the same task, pointing each at its own scripts folder:

``` r
setwd("~/Downloads/testes")
library(harness)
setup("data-scientist", scaffold = TRUE)

launch("claude",   role = "data-scientist")
launch("codex",    role = "data-scientist")
launch("opencode", role = "data-scientist")
```

In each coder terminal, paste the same task and direct it to a coder-specific
folder. For claude:

```
Classify the iris species. Write a SINGLE R script to
analysis/scripts_claude/2026-06-04_iris-classification.R that uses set.seed(42),
a stratified 70/30 split by Species, nnet::multinom, the test-set accuracy and a
confusion matrix, and saves two ggplot2 figures to output/figures/. Follow the
project instructions: native pipe, a short comment above each block, do not
execute anything, only write the script.
```

Repeat in the codex and opencode terminals with `analysis/scripts_codex/` and
`analysis/scripts_opencode/`. Each agent writes its script and a decision log
under `logs/`, and runs nothing. You then read and run each script yourself and
compare:

``` r
source("analysis/scripts_claude/2026-06-04_iris-classification.R")
source("analysis/scripts_codex/2026-06-04_iris-classification.R")
source("analysis/scripts_opencode/2026-06-04_iris-classification.R")
```

The separate folders keep the three implementations side by side, while the
decision logs record why each agent made its choices.

## Roles in this version

Seventeen curated harnesses ship in the current development version. List them
with `role_list()`:

| Role | Focus |
|---|---|
| `data-scientist` | exploratory analysis and communication with the tidyverse |
| `statistician` | mixed models, survival, Bayesian inference, marginal effects |
| `package-maintainer` | package development, tests, documentation, CRAN preparation |
| `paper-author` | reproducible papers in R Markdown or Quarto |
| `data-engineer` | columnar formats, embedded engines, database pipelines |
| `ml-engineer` | tidymodels training, evaluation and deployment artifacts |
| `shiny-developer` | modular Shiny applications |
| `code-documenter` | roxygen2 docstrings and reference sites |
| `econometrician` | panel models, fixed effects, time series |
| `epidemiologist` | outbreak reconstruction and reproduction numbers |
| `clinical-biostat` | CDISC derivation and regulatory tables with the pharmaverse |
| `geospatial-analyst` | vector and raster analysis, thematic mapping |
| `causal-inference` | difference-in-differences, matching, causal graphs |
| `forecast-specialist` | time series forecasting with the tidyverts stack |
| `reproducibility-engineer` | dependency pinning and pipeline orchestration |
| `bioinformatician` | Bioconductor sequence and expression analysis |
| `performance-engineer` | optimisation under a hard output-equivalence gate |

Each harness is a proposal open to contribution; refinements are welcome by pull
request.

## Audit-first convention

Every harness pins `execution_policy: manual`. The package rejects, at load
time, any harness that does not. The system prompt of each role instructs the
agent to write scripts into the role's layout folders and to leave execution to
the user. The agent writes, the user runs.

## Decision log

Every role, including roles contributed later, carries a decision-log
convention. The agent writes one Markdown file per step to `logs/`, named
`<YYYY-MM-DD>_<NN>_<slug>.md`, with three sections: `Decision`, `Justification`
and `Result`. The `Result` section lists the files written and leaves a line for
the run outcome, filled after the user runs the script. The `logs/` directory is
scaffolded for every role and the entries form an audit trail that pairs each
generated artifact with the reasoning behind it.

## License

MIT, see [LICENSE](LICENSE).
