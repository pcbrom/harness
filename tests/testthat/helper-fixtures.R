# Build a throwaway community-skills checkout holding the named skills, each
# with a minimal SKILL.md. The directory is removed when `envir` is cleared.
make_fake_checkout <- function(skills, envir = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = envir)
  for (s in skills) {
    d <- file.path(root, "skills", s)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    writeLines(
      c("---", paste0("name: ", s), "---", "fixture skill"),
      file.path(d, "SKILL.md")
    )
  }
  normalizePath(root, mustWork = FALSE)
}

# A throwaway project directory.
make_fake_project <- function(envir = parent.frame()) {
  withr::local_tempdir(.local_envir = envir)
}
