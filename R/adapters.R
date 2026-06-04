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

# The set of adapters shipped in this version. The remaining coders (aider,
# gemini-cli) are added in later phases.
adapter_registry <- function() {
  list(
    claude = adapter_claude(),
    opencode = adapter_opencode(),
    codex = adapter_codex()
  )
}

# ---------------------------------------------------------------------------
# Shared adapter helpers. Each coder differs only in the config file it writes
# and in where it reads skills and prompt from; the linking, the namespaced
# block and the prompt body are common.
# ---------------------------------------------------------------------------

# Link the curated skills present in the checkout into skills_root as symlinks.
# Returns linked, missing and conflicting skill names. A pre-existing link to
# the same source counts as linked; anything else at the destination is a
# conflict and is never overwritten.
harness_link_skills <- function(skills, skills_root, cs_path) {
  dir.create(skills_root, recursive = TRUE, showWarnings = FALSE)
  linked <- character()
  missing <- character()
  conflict <- character()
  for (skill in skills) {
    src <- skill_dir(cs_path, skill)
    if (!file.exists(file.path(src, "SKILL.md"))) {
      missing <- c(missing, skill)
      next
    }
    dest <- file.path(skills_root, skill)
    nsrc <- normalizePath(src, mustWork = FALSE)
    link <- Sys.readlink(dest)
    if (file.exists(dest) || (!is.na(link) && nzchar(link))) {
      if (!is.na(link) && nzchar(link) &&
          normalizePath(link, mustWork = FALSE) == nsrc) {
        linked <- c(linked, skill)
      } else {
        conflict <- c(conflict, skill)
      }
      next
    }
    ok <- tryCatch(
      file.symlink(nsrc, dest),
      error = function(e) FALSE,
      warning = function(w) FALSE
    )
    if (isTRUE(ok)) {
      linked <- c(linked, skill)
    } else {
      conflict <- c(conflict, skill)
    }
  }
  list(skills_root = skills_root, linked = linked,
       missing = missing, conflict = conflict)
}

# The namespaced harness block merged into a coder config file.
harness_config_block <- function(h, project_dir, skills_linked, prompt_rel) {
  list(
    role = h$name,
    version = h$version %||% "0.0.0",
    generated_by = "harness R package",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    project_dir = project_dir,
    execution_policy = "manual",
    skills = as.list(skills_linked),
    prompt_file = prompt_rel
  )
}

# The role prompt body, including the manual-execution policy.
harness_prompt_body <- function(h) {
  paste0(
    "# Harness: ", h$name, "\n\n",
    trimws(h$system_prompt), "\n\n",
    "## Execution policy\n\n",
    "Execution of generated code is manual. Write scripts to the layout ",
    "folders; do not call `source()`, `Rscript`, `system()` or any ",
    "autonomous execution. The user runs every script.\n"
  )
}

# Write the role prompt to AGENTS.md, the cross-tool agent-instructions
# convention read by opencode and codex. When AGENTS.md already exists it is
# never overwritten; the prompt goes to <alt_dir>/harness-<role>.md instead.
# Returns the project-relative path written.
harness_write_agents <- function(h, project_dir, alt_dir) {
  body <- harness_prompt_body(h)
  main <- file.path(project_dir, "AGENTS.md")
  if (!file.exists(main)) {
    writeLines(body, main)
    return("AGENTS.md")
  }
  d <- file.path(project_dir, alt_dir)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  alt <- file.path(d, paste0("harness-", h$name, ".md"))
  writeLines(body, alt)
  file.path(alt_dir, paste0("harness-", h$name, ".md"))
}

# Merge a harness block into a JSON config file, preserving existing keys, and
# write it back. extra is an optional named list of keys to set as well.
harness_write_json_config <- function(path, block, extra = list()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  current <- list()
  if (file.exists(path)) {
    current <- tryCatch(
      jsonlite::read_json(path, simplifyVector = FALSE),
      error = function(e) list()
    )
    if (!is.list(current)) {
      current <- list()
    }
  }
  for (nm in names(extra)) {
    current[[nm]] <- extra[[nm]]
  }
  current$harness <- block
  jsonlite::write_json(
    current, path, auto_unbox = TRUE, pretty = TRUE, null = "null"
  )
  path
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
