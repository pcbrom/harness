# Reference adapter: Claude Code. The other four coders follow this shape.
#
# Claude Code discovers skills under <config_home>/skills/<skill>/SKILL.md and
# reads project instructions from <project>/.claude/CLAUDE.md. This adapter
# links the curated skills into the skills directory, writes a namespaced
# harness block into settings.json without disturbing existing keys, and places
# the role system prompt where Claude Code will read it. It never spawns a
# process; launch() owns the terminal.

# Default configuration home for Claude Code.
claude_config_home <- function() {
  file.path(path.expand("~"), ".claude")
}

# Place the role system prompt where Claude Code reads it. The project's
# CLAUDE.md is written only when absent; otherwise the prompt goes to a
# role-specific file so an existing CLAUDE.md is never overwritten.
claude_write_prompt <- function(h, project_dir) {
  claude_dir <- file.path(project_dir, ".claude")
  dir.create(claude_dir, recursive = TRUE, showWarnings = FALSE)
  body <- harness_prompt_body(h)
  main <- file.path(claude_dir, "CLAUDE.md")
  if (!file.exists(main)) {
    writeLines(body, main)
    return(file.path(".claude", "CLAUDE.md"))
  }
  alt <- file.path(claude_dir, paste0("harness-", h$name, ".md"))
  writeLines(body, alt)
  file.path(".claude", paste0("harness-", h$name, ".md"))
}

# The adapter object.
adapter_claude <- function() {
  list(
    name = "claude",

    find_binary = function() {
      find_binary("claude")
    },

    build_config = function(harness, project_dir, opts = list()) {
      config_home <- opts$config_home %||% claude_config_home()
      cs_path <- opts$skills_path %||% community_skills_path()
      if (is.na(cs_path)) {
        harness_abort(
          "community-skills checkout not found; run setup() first.",
          class = "harness_no_community_skills"
        )
      }
      dir.create(project_dir, recursive = TRUE, showWarnings = FALSE)
      links <- harness_link_skills(
        harness$skills, file.path(config_home, "skills"), cs_path
      )
      prompt_rel <- claude_write_prompt(harness, project_dir)
      block <- harness_config_block(
        harness, project_dir, links$linked, prompt_rel
      )
      settings_path <- harness_write_json_config(
        file.path(config_home, "settings.json"), block
      )
      list(
        adapter = "claude",
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
      bin <- opts$binary %||% find_binary("claude")
      if (is.na(bin)) {
        bin <- "claude"
      }
      list(command = bin, args = character(), workdir = opts$project_dir %||% getwd())
    }
  )
}
