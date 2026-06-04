# opencode adapter. opencode reads a project-scoped opencode.json and the
# AGENTS.md instructions file. opencode validates opencode.json against its
# schema and rejects unknown keys, so this adapter writes only valid keys:
# it points opencode's instructions at the role prompt and links the curated
# skills under .opencode/skills. Existing user keys are preserved.

# Write opencode.json with only valid keys, preserving any existing user keys.
# Ensures the schema and that the role prompt is listed in instructions, and
# strips a `harness` key left by earlier versions of this package.
opencode_write_config <- function(path, prompt_rel) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  current <- list()
  if (file.exists(path)) {
    current <- tryCatch(
      jsonlite::read_json(path, simplifyVector = FALSE),
      error = function(e) list()
    )
    if (!is.list(current)) {
      current <- list()
    }
  }
  current$harness <- NULL
  current[["$schema"]] <- "https://opencode.ai/config.json"
  instructions <- unique(c(
    as.character(unlist(current$instructions)), prompt_rel
  ))
  current$instructions <- as.list(instructions)
  jsonlite::write_json(current, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  path
}

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
      config_path <- opencode_write_config(
        file.path(config_home, "opencode.json"), prompt_rel
      )
      list(
        adapter = "opencode",
        config_home = config_home,
        config_path = config_path,
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
