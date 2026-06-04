# Startup behaviour. When the community-skills catalogue is not discoverable,
# the package points the user at the command that fetches it. When it is
# present and the user opted in, the catalogue is updated on load. No network
# access and no filesystem writes happen by default: the message only declares
# the command, and the auto-update runs solely under an explicit opt-in.

.onAttach <- function(libname, pkgname) {
  cs <- community_skills_path()

  if (is.na(cs)) {
    packageStartupMessage(
      "harness: community-skills catalogue not found.\n",
      "  Fetch it with:  harness::clone_community_skills()\n",
      "  Or set COMMUNITY_SKILLS_PATH to an existing checkout."
    )
    return(invisible())
  }

  if (harness_auto_update_enabled()) {
    res <- tryCatch(
      update_community_skills(cs, quiet = TRUE),
      error = function(e) e
    )
    if (inherits(res, "error")) {
      packageStartupMessage(
        "harness: community-skills auto-update skipped (",
        conditionMessage(res), ")."
      )
    } else {
      packageStartupMessage("harness: community-skills updated at ", cs, ".")
    }
    return(invisible())
  }

  invisible()
}
