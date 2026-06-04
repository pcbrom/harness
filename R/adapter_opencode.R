# opencode adapter. opencode reads a project-scoped opencode.json and the
# AGENTS.md instructions file. This adapter writes the harness block into
# opencode.json (preserving existing keys), points opencode's instructions at
# the role prompt, and links the curated skills under .opencode/skills.

adapter_opencode <- function() {
  list(
    name = "opencode",

    find_binary = function() {
      find_binary("opencode")
    },

    build_config = function(harness, project_dir, opts = list()) {
      cs_path <- opts$skills_path %||% community_skills_path()
      if (is.na(cs_path)) {
        harness_abort(
          "community-skills checkout not found; run setup() first.",
          class = "harness_no_community_skills"
        )
      }
      config_home <- opts$config_home %||% project_dir
      dir.create(project_dir, recursive = TRUE, showWarnings = FALSE)
      links <- harness_link_skills(
        harness$skills, file.path(config_home, ".opencode", "skills"), cs_path
      )
      prompt_rel <- harness_write_agents(harness, project_dir, ".opencode")
      block <- harness_config_block(
        harness, project_dir, links$linked, prompt_rel
      )
      settings_path <- harness_write_json_config(
        file.path(config_home, "opencode.json"), block,
        extra = list(
          "$schema" = "https://opencode.ai/config.json",
          instructions = list(prompt_rel)
        )
      )
      list(
        adapter = "opencode",
        config_home = config_home,
        settings_path = settings_path,
        prompt_file = file.path(project_dir, prompt_rel),
        skills_root = links$skills_root,
        skills_linked = links$linked,
        skills_missing = links$missing,
        skills_conflict = links$conflict
      )
    },

    terminal_command = function(config, opts = list()) {
      bin <- opts$binary %||% find_binary("opencode")
      if (is.na(bin)) {
        bin <- "opencode"
      }
      list(command = bin, args = character(),
           workdir = opts$project_dir %||% getwd())
    }
  )
}
