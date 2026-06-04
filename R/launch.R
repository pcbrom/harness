# Orchestrator: load a role, configure the chosen coder, open a terminal tab.

#' Launch a curated coding session
#'
#' Loads the harness for `role`, configures the chosen `adapter` for the
#' project, scaffolds the role's folder layout, and opens the coder in a
#' terminal tab. Inside RStudio the terminal is created with
#' `rstudioapi::terminalCreate`; otherwise an external terminal emulator is
#' used, and when none is available the launch command is reported for the user
#' to run.
#'
#' The package never runs an agent loop and never executes code produced by the
#' agent. Generated scripts are run manually by the user.
#'
#' @param adapter The coder to launch. See [adapters()].
#' @param role The professional role. See [available_roles()].
#' @param project_dir The project root. Defaults to the working directory.
#' @param scaffold When `TRUE` (the default), creates the role's folder layout.
#' @param dry_run When `TRUE`, configures everything but does not open a
#'   terminal. Useful for inspection and testing.
#' @param config_home Override the adapter configuration home (mainly for
#'   testing).
#' @param skills_path Override the community-skills checkout path.
#' @param binary Override the discovered coder binary path.
#' @return An object of class `harness_launch`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' launch("claude", role = "data-scientist")
#' }
launch <- function(adapter = "claude", role, project_dir = getwd(),
                   scaffold = TRUE, dry_run = FALSE,
                   config_home = NULL, skills_path = NULL, binary = NULL) {
  if (missing(role)) {
    harness_abort("`role` is required. See available_roles().")
  }
  ad <- get_adapter(adapter)
  h <- load_harness(role)
  project_dir <- normalizePath(project_dir, mustWork = FALSE)

  opts <- list(
    config_home = config_home,
    skills_path = skills_path,
    binary = binary,
    project_dir = project_dir
  )

  if (isTRUE(scaffold)) {
    scaffold_layout(h, project_dir, create = TRUE)
  }

  config <- ad$build_config(h, project_dir, opts)
  cmd <- ad$terminal_command(config, opts)

  launch_obj <- structure(
    list(
      adapter = adapter,
      role = h$name,
      project_dir = project_dir,
      config = config,
      command = cmd,
      dry_run = isTRUE(dry_run),
      spawned = FALSE,
      method = "none"
    ),
    class = "harness_launch"
  )

  if (isTRUE(dry_run)) {
    return(invisible(launch_obj))
  }

  bin <- binary %||% cmd$command
  if (is.na(bin) || !nzchar(bin)) {
    harness_abort(
      sprintf("coder binary for adapter '%s' not found.", adapter),
      class = "harness_no_binary"
    )
  }

  spawn <- spawn_terminal(bin, cmd$args, project_dir, adapter, h$name)
  launch_obj$spawned <- spawn$spawned
  launch_obj$method <- spawn$method
  if (!spawn$spawned) {
    message(spawn$message)
  }
  invisible(launch_obj)
}

# Open a terminal running the coder. Returns the spawn method and status.
spawn_terminal <- function(bin, args, project_dir, adapter, role) {
  shell_cmd <- paste(c(shQuote(bin), args), collapse = " ")

  if (is_rstudio_terminal()) {
    caption <- unique_terminal_caption(paste0("harness:", adapter, ":", role))
    id <- rstudioapi::terminalCreate(caption = caption, show = TRUE)
    rstudioapi::terminalSend(id, paste0("cd ", shQuote(project_dir), "\n"))
    rstudioapi::terminalSend(id, paste0(shell_cmd, "\n"))
    return(list(spawned = TRUE, method = "rstudio", message = ""))
  }

  emulator <- find_terminal_emulator()
  if (!is.null(emulator)) {
    ok <- spawn_external(emulator, shell_cmd, project_dir)
    if (ok) {
      return(list(spawned = TRUE, method = emulator$name, message = ""))
    }
  }

  list(
    spawned = FALSE,
    method = "manual",
    message = paste0(
      "No terminal available to open automatically. Run, in ",
      project_dir, ":\n  ", shell_cmd
    )
  )
}

# Find a terminal caption not already in use. RStudio rejects terminalCreate
# when the caption is taken, so repeated launches need a fresh one. Falls back
# to the base caption when the terminal list cannot be read.
unique_terminal_caption <- function(base) {
  existing <- character()
  if (requireNamespace("rstudioapi", quietly = TRUE)) {
    existing <- tryCatch({
      ids <- rstudioapi::terminalList()
      vapply(ids, function(id) {
        ctx <- tryCatch(rstudioapi::terminalContext(id), error = function(e) NULL)
        if (is.null(ctx)) "" else as.character(ctx$caption %||% "")
      }, character(1))
    }, error = function(e) character())
  }
  if (!base %in% existing) {
    return(base)
  }
  for (i in 2:99) {
    cand <- paste0(base, " (", i, ")")
    if (!cand %in% existing) {
      return(cand)
    }
  }
  paste0(base, " ", as.integer(Sys.time()))
}

# Spawn the coder in an external terminal emulator, detached. Returns TRUE on a
# successful launch dispatch.
spawn_external <- function(emulator, shell_cmd, project_dir) {
  inner <- paste0("cd ", shQuote(project_dir), "; ", shell_cmd, "; exec ${SHELL:-bash}")
  args <- switch(
    emulator$name,
    "gnome-terminal" = c("--", "bash", "-lc", shQuote(inner)),
    "konsole" = c("-e", "bash", "-lc", shQuote(inner)),
    "x-terminal-emulator" = c("-e", "bash", "-lc", shQuote(inner)),
    "xterm" = c("-e", "bash", "-lc", shQuote(inner)),
    "open" = c("-a", "Terminal", project_dir),
    c("-e", "bash", "-lc", shQuote(inner))
  )
  status <- tryCatch(
    system2(emulator$launch, args, stdout = FALSE, stderr = FALSE, wait = FALSE),
    error = function(e) 127L
  )
  identical(as.integer(status), 0L) || is.null(status)
}

#' @export
print.harness_launch <- function(x, ...) {
  cat(sprintf("<harness launch> %s via %s\n", x$role, x$adapter))
  cat(sprintf("  project: %s\n", x$project_dir))
  cat(sprintf("  settings: %s\n", x$config$settings_path))
  cat(sprintf("  skills linked: %d", length(x$config$skills_linked)))
  if (length(x$config$skills_missing) > 0L) {
    cat(sprintf(" (%d missing in checkout)", length(x$config$skills_missing)))
  }
  cat("\n")
  cat(sprintf("  command: %s\n", paste(c(x$command$command, x$command$args),
                                       collapse = " ")))
  if (x$dry_run) {
    cat("  dry run: terminal not opened\n")
  } else {
    cat(sprintf("  launched via: %s\n", x$method))
  }
  invisible(x)
}
