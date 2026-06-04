# Startup behaviour. When the community-skills catalogue is not discoverable,
# the package points the user at the command that fetches it. No network access
# and no filesystem writes happen on load: the message only declares the command.

.onAttach <- function(libname, pkgname) {
  if (is.na(community_skills_path())) {
    packageStartupMessage(
      "harness: community-skills catalogue not found.\n",
      "  Fetch it with:  harness::clone_community_skills()\n",
      "  Or set COMMUNITY_SKILLS_PATH to an existing checkout."
    )
  }
}
