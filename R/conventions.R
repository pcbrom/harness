# Folder-layout scaffolding for a harness inside a project directory.

# Return the layout of a harness as a named character vector of relative paths.
harness_layout <- function(h) {
  layout <- h$layout %||% list()
  vapply(layout, as.character, character(1))
}

#' Scaffold the folder layout of a role
#'
#' Creates the directories declared in the harness `layout` under
#' `project_dir`. Existing directories are left untouched. The function never
#' writes code, runs a script, or removes anything; it only ensures the audit
#' folders exist.
#'
#' @param role_name A role name, as returned by [available_roles()].
#' @param project_dir The project root under which to create the layout.
#' @param create When `FALSE` (the default), the function reports the directories
#'   that would be created without touching the filesystem. Set to `TRUE` to
#'   create them.
#' @return A data frame with one row per layout entry, invisibly.
#' @export
#' @examples
#' tmp <- tempfile("proj")
#' dir.create(tmp)
#' scaffold_layout("data-scientist", tmp, create = TRUE)
scaffold_layout <- function(role_name, project_dir = getwd(), create = FALSE) {
  h <- if (inherits(role_name, "harness_role")) role_name else role(role_name)
  layout <- harness_layout(h)
  if (length(layout) == 0L) {
    return(invisible(data.frame(
      key = character(), path = character(), existed = logical(),
      stringsAsFactors = FALSE
    )))
  }
  abs_paths <- file.path(project_dir, layout)
  existed <- dir.exists(abs_paths)
  if (isTRUE(create)) {
    for (p in abs_paths[!existed]) {
      dir.create(p, recursive = TRUE, showWarnings = FALSE)
    }
  }
  out <- data.frame(
    key = names(layout),
    path = unname(layout),
    existed = existed,
    stringsAsFactors = FALSE
  )
  invisible(out)
}
