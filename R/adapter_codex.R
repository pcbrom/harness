# codex adapter. codex reads the AGENTS.md instructions file and a project
# .codex directory. This adapter writes the role prompt to AGENTS.md and links
# the curated skills under .codex/skills. It does not write a config file with
# package-specific keys, to avoid disturbing codex configuration.

adapter_codex <- function() {
  list(
    name = "codex",

    find_binary = function() {
      find_binary("codex")
    },

    build_config = function(harness, project_dir, opts = list()) {
      cs_path <- opts$skills_path %||% community_skills_path()
      if (is.na(cs_path)) {
        harness_abort(
          "community-skills checkout not found; run setup() first.",
          class = "harness_no_community_skills"
        )
      }
      config_home <- opts$config_home %||% file.path(project_dir, ".codex")
      dir.create(config_home, recursive = TRUE, showWarnings = FALSE)
      links <- harness_link_skills(
        harness$skills, file.path(config_home, "skills"), cs_path
      )
      prompt_rel <- harness_write_agents(harness, project_dir, ".codex")
      list(
        adapter = "codex",
        config_home = config_home,
        config_path = NA_character_,
        prompt_file = file.path(project_dir, prompt_rel),
        skills_root = links$skills_root,
        skills_linked = links$linked,
        skills_missing = links$missing,
        skills_conflict = links$conflict
      )
    },

    terminal_command = function(config, opts = list()) {
      bin <- opts$binary %||% find_binary("codex")
      if (is.na(bin)) {
        bin <- "codex"
      }
      list(command = bin, args = character(),
           workdir = opts$project_dir %||% getwd())
    }
  )
}
