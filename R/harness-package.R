#' harness: curated agentic harnesses for R professional roles
#'
#' The package launches a command-line coding agent of the user's choice in a
#' terminal tab pre-configured for a professional R role. A role is described
#' by a curated harness stored in `inst/harness/<role>.yml`: a subset of
#' community skills, a system prompt, a folder layout, and quality gates.
#'
#' The package does not run an agent loop and does not call a language model.
#' It discovers the chosen coder binary, generates its configuration, links the
#' curated skills, and opens the terminal. Code written by the agent is run
#' manually by the user, so that every generated script passes through a human
#' audit gate before execution.
#'
#' Entry points: [status()], [setup()], [available_roles()], [role()] and
#' [launch()].
#'
#' @keywords internal
"_PACKAGE"

# Null-coalescing helper used across the package.
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x
