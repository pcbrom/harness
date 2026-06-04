# Adapter registry. Each adapter is a list of functions that isolate the
# specifics of one command-line coder behind a stable interface:
#
#   find_binary()                              -> path or NA_character_
#   build_config(harness, project_dir, opts)   -> list describing what it wrote
#   terminal_command(config, opts)             -> list(command, args, env)
#
# build_config writes configuration and links skills but never spawns a
# process; launch() owns the terminal. terminal_command returns the shell
# invocation only.

# The set of adapters shipped in this version. Phase 1 ships claude; the
# remaining four coders are added in later phases.
adapter_registry <- function() {
  list(
    claude = adapter_claude()
  )
}

#' List the registered adapters
#'
#' @return A character vector of adapter names.
#' @export
#' @examples
#' adapters()
adapters <- function() {
  names(adapter_registry())
}

# Resolve an adapter by name, aborting on an unknown coder.
get_adapter <- function(name) {
  reg <- adapter_registry()
  if (!name %in% names(reg)) {
    harness_abort(
      sprintf(
        "unknown adapter '%s'. Available adapters: %s",
        name, paste(names(reg), collapse = ", ")
      ),
      class = "harness_unknown_adapter"
    )
  }
  reg[[name]]
}
