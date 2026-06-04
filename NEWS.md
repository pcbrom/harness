# harness 0.1.0

First release.

* Launches a command-line coding agent (`claude`, `opencode` or `codex`) in a
  terminal tab pre-configured for one of seventeen professional R roles, with
  curated skills from the external community-skills catalogue, a role system
  prompt, a folder layout and quality gates.
* Audit-first convention: every role pins manual execution. The agent writes
  scripts into the role's layout folders and a per-step decision log under
  `logs/`, and never runs them; the user runs every script.
* Public API: `status()`, `setup()`, `available_roles()`, `role()`,
  `role_list()`, `role_skills()`, `role_config()`, `launch()`, `adapters()`,
  `scaffold_layout()`, `community_skills_path()`, `clone_community_skills()` and
  `update_community_skills()`.
* The community-skills catalogue is an external dependency, discovered at
  runtime and never bundled. The package accesses the network only when the user
  calls `clone_community_skills()` or `update_community_skills()`.
