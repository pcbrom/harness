# Harness catalogue: discovery, loading, schema validation and introspection.

# Required top-level keys in every inst/harness/<role>.yml file.
harness_required_fields <- c(
  "name", "version", "description", "skills", "system_prompt",
  "layout", "execution_policy"
)

#' List the available curated roles
#'
#' Returns the names of the harnesses bundled with the package, taken from the
#' `inst/harness/<role>.yml` catalogue.
#'
#' @return A character vector of role names, sorted alphabetically.
#' @export
#' @examples
#' available_roles()
available_roles <- function() {
  dir <- harness_catalogue_dir()
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(character())
  }
  files <- list.files(dir, pattern = "\\.ya?ml$", full.names = FALSE)
  sort(sub("\\.ya?ml$", "", files))
}

#' Tabulate the available roles
#'
#' Returns a data frame with one row per curated role, summarising its version,
#' the number of skills it declares, and the first line of its description.
#'
#' @return A data frame with columns `role`, `version`, `skills` and
#'   `description`.
#' @export
#' @examples
#' role_list()
role_list <- function() {
  roles <- available_roles()
  if (length(roles) == 0L) {
    return(data.frame(
      role = character(), version = character(),
      skills = integer(), description = character(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(roles, function(nm) {
    h <- role(nm)
    first_line <- trimws(strsplit(h$description %||% "", "\n", fixed = TRUE)[[1]][1])
    data.frame(
      role = nm,
      version = h$version %||% NA_character_,
      skills = length(h$skills),
      description = first_line %||% "",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' List the skills of one or more roles
#'
#' Returns a long data frame with one row per role-skill pair. With
#' `available = TRUE`, each skill is checked against the community-skills
#' checkout and an `available` column reports whether its SKILL.md is present.
#'
#' @param role_name A role name, or `NULL` (the default) for every role.
#' @param available When `TRUE`, add an `available` column reporting whether the
#'   skill is present in the community-skills checkout.
#' @return A data frame with columns `role` and `skill`, plus `available` when
#'   requested.
#' @export
#' @examples
#' role_skills("data-scientist")
#' utils::head(role_skills())
role_skills <- function(role_name = NULL, available = FALSE) {
  names_ <- role_name %||% available_roles()
  cs <- if (isTRUE(available)) community_skills_path() else NA_character_
  rows <- lapply(names_, function(nm) {
    h <- role(nm)
    df <- data.frame(role = nm, skill = h$skills, stringsAsFactors = FALSE)
    if (isTRUE(available)) {
      df$available <- vapply(
        h$skills,
        function(s) !is.na(cs) && skill_available(cs, s),
        logical(1)
      )
    }
    df
  })
  do.call(rbind, rows)
}

# Resolve a role name to its YAML path inside the catalogue.
harness_path <- function(name) {
  dir <- harness_catalogue_dir()
  for (ext in c("yml", "yaml")) {
    cand <- file.path(dir, paste0(name, ".", ext))
    if (file.exists(cand)) {
      return(cand)
    }
  }
  NA_character_
}

# Read and normalise a harness YAML into a plain list. No validation here.
read_harness_yaml <- function(path) {
  raw <- yaml::read_yaml(path)
  raw$skills <- as_character_vector(raw$skills)
  raw$quality_gates <- as_character_vector(raw$quality_gates)
  raw$deps_check <- as_character_vector(raw$deps_check)
  raw$optional_deps <- as_character_vector(raw$optional_deps)
  raw
}

# Validate a harness list against the schema. Returns the list invisibly on
# success, aborts with a harness_error otherwise.
validate_harness <- function(h, source = "<harness>") {
  missing <- setdiff(harness_required_fields, names(h))
  if (length(missing) > 0L) {
    harness_abort(
      sprintf(
        "harness '%s' is missing required field(s): %s",
        source, paste(missing, collapse = ", ")
      ),
      class = "harness_schema_error"
    )
  }
  if (length(h$skills) == 0L) {
    harness_abort(
      sprintf("harness '%s' declares no skills", source),
      class = "harness_schema_error"
    )
  }
  if (!is.list(h$layout) || is.null(names(h$layout))) {
    harness_abort(
      sprintf("harness '%s' must declare a named 'layout' mapping", source),
      class = "harness_schema_error"
    )
  }
  # Caveat 2: manual execution is structural, not advisory. A harness that does
  # not pin its execution policy to "manual" is rejected at load time.
  if (!identical(as.character(h$execution_policy), "manual")) {
    harness_abort(
      sprintf(
        "harness '%s' must set execution_policy: manual (got '%s')",
        source, as.character(h$execution_policy)
      ),
      class = "harness_policy_error"
    )
  }
  invisible(h)
}

#' Load a curated role
#'
#' Reads the harness for `name` from the catalogue, validates it against the
#' schema, and returns it as a `harness_role` object.
#'
#' @param name A role name, as returned by [available_roles()].
#' @return An object of class `harness_role`.
#' @export
#' @examples
#' ds <- role("data-scientist")
#' ds$skills
role <- function(name) {
  if (missing(name) || length(name) != 1L || !nzchar(name)) {
    harness_abort("`name` must be a single non-empty role name")
  }
  path <- harness_path(name)
  if (is.na(path)) {
    harness_abort(
      sprintf(
        "unknown role '%s'. Available roles: %s",
        name, paste(available_roles(), collapse = ", ")
      ),
      class = "harness_unknown_role"
    )
  }
  h <- read_harness_yaml(path)
  validate_harness(h, source = name)
  structure(h, class = "harness_role", path = path)
}

# Internal alias used by other modules; identical to role() but explicit.
load_harness <- function(name) role(name)

#' Show the full configuration of a role
#'
#' Prints the complete harness configuration for a role: description, execution
#' policy, skills, folder layout, quality gates, package dependencies and the
#' full system prompt, followed by the path to the source YAML. Unlike the
#' compact `print` method, this includes the system prompt in full.
#'
#' @param name A role name, or a `harness_role` object.
#' @return The `harness_role` object, invisibly.
#' @export
#' @examples
#' role_config("data-scientist")
role_config <- function(name) {
  h <- if (inherits(name, "harness_role")) name else role(name)
  cat(sprintf("Role: %s (v%s)\n", h$name, h$version %||% "?"))
  cat(sprintf("Execution policy: %s (agent writes, user runs)\n",
              h$execution_policy))
  cat("\nDescription:\n")
  cat(strwrap(trimws(h$description %||% ""), prefix = "  "), sep = "\n")
  cat(sprintf("\n\nSkills (%d):\n", length(h$skills)))
  cat(paste0("  - ", h$skills), sep = "\n")
  cat("\n\nLayout:\n")
  for (k in names(h$layout)) {
    cat(sprintf("  %-12s %s\n", k, as.character(h$layout[[k]])))
  }
  if (length(h$quality_gates) > 0L) {
    cat("\nQuality gates:\n")
    cat(paste0("  - ", h$quality_gates), sep = "\n")
    cat("\n")
  }
  if (length(h$deps_check) > 0L) {
    cat(sprintf("\nRequired packages: %s\n", paste(h$deps_check, collapse = ", ")))
  }
  if (length(h$optional_deps) > 0L) {
    cat(sprintf("Optional packages: %s\n", paste(h$optional_deps, collapse = ", ")))
  }
  cat("\nSystem prompt:\n")
  prompt_lines <- strsplit(trimws(h$system_prompt %||% ""), "\n", fixed = TRUE)[[1]]
  cat(paste0("  ", prompt_lines), sep = "\n")
  path <- attr(h, "path")
  if (!is.null(path)) {
    cat(sprintf("\n\nSource: %s\n", path))
  }
  invisible(h)
}

#' @export
print.harness_role <- function(x, ...) {
  cat(sprintf("<harness_role> %s (v%s)\n", x$name, x$version %||% "?"))
  desc <- trimws(x$description %||% "")
  if (nzchar(desc)) {
    cat(strwrap(desc, prefix = "  ", initial = "  "), sep = "\n")
    cat("\n")
  }
  cat(sprintf("  skills (%d): %s\n", length(x$skills),
              paste(x$skills, collapse = ", ")))
  layout_keys <- names(x$layout)
  cat(sprintf("  layout: %s\n", paste(layout_keys, collapse = ", ")))
  if (length(x$quality_gates) > 0L) {
    cat(sprintf("  quality gates: %s\n", paste(x$quality_gates, collapse = ", ")))
  }
  cat("  execution policy: manual (agent writes, user runs)\n")
  invisible(x)
}
