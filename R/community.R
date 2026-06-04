# Convenience fetch of the external community-skills catalogue. The catalogue
# is never bundled; this clones it into a discoverable location so that
# community_skills_path() finds it afterwards. The download is user-initiated,
# never run on load.

# Default remote for the community-skills catalogue.
community_skills_url <- function() {
  "https://github.com/pcbrom/community-skills.git"
}

#' Clone the community-skills catalogue
#'
#' Clones the external community-skills repository into a discoverable location
#' so that [community_skills_path()] finds it on the next call. The catalogue is
#' an external dependency and is never bundled with this package; this helper
#' only automates the checkout. It is never run when the package is loaded.
#'
#' @param dest Destination directory. Defaults to `~/.community-skills`, one of
#'   the paths searched by [community_skills_path()].
#' @param url The git remote to clone from.
#' @param shallow When `TRUE` (the default), performs a shallow clone.
#' @param quiet Suppress git and progress messages.
#' @return The absolute path to the checkout, invisibly.
#' @export
#' @examples
#' \dontrun{
#' clone_community_skills()
#' }
clone_community_skills <- function(dest = file.path(path.expand("~"), ".community-skills"),
                                   url = community_skills_url(),
                                   shallow = TRUE, quiet = FALSE) {
  if (is_community_skills_root(dest)) {
    if (!quiet) {
      message("community-skills already present at ", dest)
    }
    return(invisible(normalizePath(dest, mustWork = FALSE)))
  }
  if (file.exists(dest) && length(list.files(dest, all.files = TRUE, no.. = TRUE)) > 0L) {
    harness_abort(
      sprintf("destination '%s' exists and is not a community-skills checkout.", dest),
      class = "harness_clone_dest_exists"
    )
  }
  git <- find_binary("git")
  if (is.na(git)) {
    harness_abort(
      paste0("git not found on PATH. Install git, or clone manually:\n  git clone ",
             url, " ", dest),
      class = "harness_no_git"
    )
  }
  args <- c("clone", if (isTRUE(shallow)) c("--depth", "1"), url, shQuote(dest))
  out <- if (isTRUE(quiet)) FALSE else ""
  code <- system2(git, args, stdout = out, stderr = out)
  if (!identical(as.integer(code), 0L) || !is_community_skills_root(dest)) {
    harness_abort("git clone of community-skills failed.", class = "harness_clone_failed")
  }
  if (!quiet) {
    message("community-skills cloned to ", dest)
  }
  invisible(normalizePath(dest, mustWork = FALSE))
}

#' Update the community-skills catalogue
#'
#' Runs a fast-forward `git pull` on an existing community-skills checkout so
#' that the curated skills track the upstream repository. The update is
#' user-initiated. It can also run when the package is attached, but only when
#' the user opts in through the `harness.auto_update` option or the
#' `HARNESS_AUTO_UPDATE` environment variable; the default does nothing on load.
#'
#' @param dest The checkout to update. Defaults to the discovered path from
#'   [community_skills_path()].
#' @param quiet Suppress git and progress messages.
#' @return The absolute path to the checkout, invisibly.
#' @export
#' @examples
#' \dontrun{
#' update_community_skills()
#' }
update_community_skills <- function(dest = community_skills_path(), quiet = FALSE) {
  if (length(dest) != 1L || is.na(dest)) {
    harness_abort(
      "community-skills checkout not found; clone it with clone_community_skills().",
      class = "harness_no_community_skills"
    )
  }
  if (!is_community_skills_root(dest)) {
    harness_abort(
      sprintf("'%s' is not a community-skills checkout.", dest),
      class = "harness_not_checkout"
    )
  }
  if (!dir.exists(file.path(dest, ".git"))) {
    harness_abort(
      sprintf("'%s' is not a git checkout; cannot update.", dest),
      class = "harness_not_git_checkout"
    )
  }
  git <- find_binary("git")
  if (is.na(git)) {
    harness_abort("git not found on PATH.", class = "harness_no_git")
  }
  out <- if (isTRUE(quiet)) FALSE else ""
  code <- system2(
    git, c("-C", shQuote(dest), "pull", "--ff-only"),
    stdout = out, stderr = out
  )
  if (!identical(as.integer(code), 0L)) {
    harness_abort("git pull of community-skills failed.", class = "harness_update_failed")
  }
  if (!quiet) {
    message("community-skills updated at ", dest)
  }
  invisible(normalizePath(dest, mustWork = FALSE))
}

# TRUE when the user opted in to updating the catalogue on load. The option
# takes precedence over the environment variable. The default is off, so the
# package does not access the network on load unless explicitly told to.
harness_auto_update_enabled <- function() {
  opt <- getOption("harness.auto_update", NULL)
  if (!is.null(opt)) {
    return(isTRUE(opt))
  }
  env <- tolower(trimws(Sys.getenv("HARNESS_AUTO_UPDATE", "")))
  env %in% c("1", "true", "yes", "on")
}
