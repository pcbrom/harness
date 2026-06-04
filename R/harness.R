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
