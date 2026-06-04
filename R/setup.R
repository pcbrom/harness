# Environment discovery and validation: community-skills, roles, adapters.

# Candidate roots for a community-skills checkout, in priority order.
community_skills_candidates <- function() {
  env <- Sys.getenv("COMMUNITY_SKILLS_PATH", unset = "")
  c(
    if (nzchar(env)) env else NULL,
    file.path(path.expand("~"), ".community-skills"),
    file.path(path.expand("~"), "projects", "community-skills")
  )
}

# A directory is a community-skills checkout when it holds a skills/ subfolder.
is_community_skills_root <- function(path) {
  nzchar(path) && dir.exists(file.path(path, "skills"))
}

#' Locate the community-skills checkout
#'
#' Searches, in order, the `COMMUNITY_SKILLS_PATH` environment variable,
#' `~/.community-skills/` and `~/projects/community-skills/`. The community
#' skills catalogue is an external dependency and is never bundled with this
#' package.
#'
#' @return The absolute path to the checkout, or `NA_character_` when none is
#'   found.
#' @export
#' @examples
#' community_skills_path()
community_skills_path <- function() {
  for (cand in community_skills_candidates()) {
    if (is_community_skills_root(cand)) {
      return(normalizePath(cand, mustWork = FALSE))
    }
  }
  NA_character_
}

# Path to a single skill directory inside a checkout (may not exist).
skill_dir <- function(cs_path, skill) {
  file.path(cs_path, "skills", skill)
}

# TRUE when a skill directory carries a SKILL.md file.
skill_available <- function(cs_path, skill) {
  file.exists(file.path(skill_dir(cs_path, skill), "SKILL.md"))
}

# Split a harness's declared skills into those present in the checkout and
# those absent. With no checkout, every skill is reported as missing.
skills_coverage <- function(h, cs_path = community_skills_path()) {
  skills <- h$skills
  if (is.na(cs_path)) {
    return(list(present = character(), missing = skills))
  }
  ok <- vapply(skills, function(s) skill_available(cs_path, s), logical(1))
  list(present = skills[ok], missing = skills[!ok])
}

# Which declared CRAN dependencies are installed.
deps_coverage <- function(h) {
  deps <- h$deps_check %||% character()
  if (length(deps) == 0L) {
    return(list(present = character(), missing = character()))
  }
  installed <- vapply(deps, function(p) {
    requireNamespace(p, quietly = TRUE)
  }, logical(1))
  list(present = deps[installed], missing = deps[!installed])
}

#' Report the harness environment status
#'
#' Summarises the discoverable environment: the community-skills checkout, the
#' bundled roles, and the registered adapters with their binary availability.
#' The function performs no side effects.
#'
#' @return An object of class `harness_status`, invisibly printed by default.
#' @export
#' @examples
#' status()
status <- function() {
  cs <- community_skills_path()
  adapters <- adapter_registry()
  adapter_state <- lapply(names(adapters), function(nm) {
    bin <- adapters[[nm]]$find_binary()
    list(name = nm, binary = bin, available = !is.na(bin))
  })
  names(adapter_state) <- names(adapters)
  out <- list(
    community_skills = cs,
    community_skills_ok = !is.na(cs),
    roles = available_roles(),
    adapters = adapter_state,
    rstudio_terminal = is_rstudio_terminal()
  )
  structure(out, class = "harness_status")
}

#' @export
print.harness_status <- function(x, ...) {
  cat("<harness status>\n")
  cat(sprintf(
    "  community-skills: %s\n",
    if (x$community_skills_ok) x$community_skills else "not found"
  ))
  cat(sprintf("  roles available : %d (%s)\n",
              length(x$roles), paste(x$roles, collapse = ", ")))
  cat("  adapters:\n")
  for (nm in names(x$adapters)) {
    a <- x$adapters[[nm]]
    cat(sprintf("    %-10s %s\n", nm,
                if (a$available) a$binary else "binary not found"))
  }
  cat(sprintf("  rstudio terminal: %s\n",
              if (x$rstudio_terminal) "yes" else "no"))
  invisible(x)
}

#' Validate the environment for a role
#'
#' Checks that a community-skills checkout exists, reports which curated skills
#' for the role are present in that checkout, and which declared CRAN packages
#' are installed. Optionally scaffolds the role's folder layout. The function
#' never installs packages and never runs generated code.
#'
#' @param role_name A role name, or `NULL` to validate only the checkout.
#' @param project_dir The project root for optional layout scaffolding.
#' @param scaffold When `TRUE`, creates the role's folder layout under
#'   `project_dir`.
#' @return An object of class `harness_setup`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' setup("data-scientist")
#' }
setup <- function(role_name = NULL, project_dir = getwd(), scaffold = FALSE) {
  cs <- community_skills_path()
  if (is.na(cs)) {
    harness_abort(paste0(
      "community-skills checkout not found. Clone it and make it discoverable ",
      "via COMMUNITY_SKILLS_PATH, ~/.community-skills/ or ",
      "~/projects/community-skills/. See ?community_skills_path."
    ), class = "harness_no_community_skills")
  }
  result <- list(community_skills = cs, role = NULL)
  if (!is.null(role_name)) {
    h <- role(role_name)
    skills <- skills_coverage(h, cs)
    deps <- deps_coverage(h)
    layout <- if (isTRUE(scaffold)) {
      scaffold_layout(h, project_dir, create = TRUE)
    } else {
      scaffold_layout(h, project_dir, create = FALSE)
    }
    result$role <- list(
      name = h$name,
      skills_present = skills$present,
      skills_missing = skills$missing,
      deps_present = deps$present,
      deps_missing = deps$missing,
      layout = layout,
      scaffolded = isTRUE(scaffold)
    )
  }
  structure(result, class = "harness_setup")
}

#' @export
print.harness_setup <- function(x, ...) {
  cat("<harness setup>\n")
  cat(sprintf("  community-skills: %s\n", x$community_skills))
  if (is.null(x$role)) {
    cat("  role: none requested\n")
    return(invisible(x))
  }
  r <- x$role
  cat(sprintf("  role: %s\n", r$name))
  cat(sprintf("    skills present: %d/%d\n",
              length(r$skills_present),
              length(r$skills_present) + length(r$skills_missing)))
  if (length(r$skills_missing) > 0L) {
    cat(sprintf("    skills missing in checkout: %s\n",
                paste(r$skills_missing, collapse = ", ")))
  }
  if (length(r$deps_missing) > 0L) {
    cat(sprintf("    R packages to install: %s\n",
                paste(r$deps_missing, collapse = ", ")))
  }
  cat(sprintf("    layout %s\n",
              if (r$scaffolded) "scaffolded" else "(not created; scaffold = FALSE)"))
  invisible(x)
}
