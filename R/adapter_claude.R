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

# Build the harness block that is merged into settings.json.
claude_harness_block <- function(h, project_dir, skills_linked, prompt_rel) {
  list(
    role = h$name,
    version = h$version %||% "0.0.0",
    generated_by = "harness R package",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    project_dir = project_dir,
    execution_policy = "manual",
    skills = as.list(skills_linked),
    prompt_file = prompt_rel
  )
}

# Merge our block into an existing settings.json (or a fresh one) and write it.
claude_write_settings <- function(settings_path, block) {
  dir.create(dirname(settings_path), recursive = TRUE, showWarnings = FALSE)
  current <- list()
  if (file.exists(settings_path)) {
    current <- tryCatch(
      jsonlite::read_json(settings_path, simplifyVector = FALSE),
      error = function(e) list()
    )
    if (!is.list(current)) {
      current <- list()
    }
  }
  current$harness <- block
  jsonlite::write_json(
    current, settings_path,
    auto_unbox = TRUE, pretty = TRUE, null = "null"
  )
  settings_path
}

# Place the role system prompt where Claude Code reads it. The project's
# CLAUDE.md is written only when absent; otherwise the prompt goes to a
# role-specific file so an existing CLAUDE.md is never overwritten.
claude_write_prompt <- function(h, project_dir) {
  claude_dir <- file.path(project_dir, ".claude")
  dir.create(claude_dir, recursive = TRUE, showWarnings = FALSE)
  body <- paste0(
    "# Harness: ", h$name, "\n\n",
    trimws(h$system_prompt), "\n\n",
    "## Execution policy\n\n",
    "Execution of generated code is manual. Write scripts to the layout ",
    "folders; do not call `source()`, `Rscript`, `system()` or any ",
    "autonomous execution. The user runs every script.\n"
  )
  main <- file.path(claude_dir, "CLAUDE.md")
  if (!file.exists(main)) {
    writeLines(body, main)
    return(file.path(".claude", "CLAUDE.md"))
  }
  alt <- file.path(claude_dir, paste0("harness-", h$name, ".md"))
  writeLines(body, alt)
  file.path(".claude", paste0("harness-", h$name, ".md"))
}

# Link the curated skills present in the checkout into the skills directory.
# Returns the linked, missing and conflicting skill names.
claude_link_skills <- function(h, config_home, cs_path) {
  skills_root <- file.path(config_home, "skills")
  dir.create(skills_root, recursive = TRUE, showWarnings = FALSE)
  linked <- character()
  missing <- character()
  conflict <- character()
  for (skill in h$skills) {
    src <- skill_dir(cs_path, skill)
    if (!file.exists(file.path(src, "SKILL.md"))) {
      missing <- c(missing, skill)
      next
    }
    dest <- file.path(skills_root, skill)
    if (file.exists(dest) || !is.na(Sys.readlink(dest)) && nzchar(Sys.readlink(dest))) {
      target <- Sys.readlink(dest)
      if (!nzchar(target) || normalizePath(target, mustWork = FALSE) !=
          normalizePath(src, mustWork = FALSE)) {
        conflict <- c(conflict, skill)
      } else {
        linked <- c(linked, skill)
      }
      next
    }
    ok <- tryCatch(
      file.symlink(normalizePath(src, mustWork = FALSE), dest),
      error = function(e) FALSE,
      warning = function(w) FALSE
    )
    if (isTRUE(ok)) {
      linked <- c(linked, skill)
    } else {
      conflict <- c(conflict, skill)
    }
  }
  list(
    skills_root = skills_root, linked = linked,
    missing = missing, conflict = conflict
  )
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
      links <- claude_link_skills(harness, config_home, cs_path)
      prompt_rel <- claude_write_prompt(harness, project_dir)
      block <- claude_harness_block(
        harness, project_dir, links$linked, prompt_rel
      )
      settings_path <- claude_write_settings(
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
