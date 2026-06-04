# Changelog

O formato segue, de forma aproximada, Keep a Changelog. As versoes seguem
versionamento semantico.

## [Unreleased]

### Fase 1 (arquitetura base, 4 harnesses, adapter claude)

Adicionado:

- Esqueleto do pacote R com DESCRIPTION valido, licenca MIT e NAMESPACE gerado
  por roxygen2.
- APIs publicas: `status()`, `setup()`, `available_roles()`, `role()` e
  `launch()`. Funcoes auxiliares exportadas: `scaffold_layout()`,
  `community_skills_path()` e `adapters()`.
- Loader e validador de harness em `R/harness.R`, lendo
  `inst/harness/<role>.yml` e checando o schema. A politica de execucao manual
  e estrutural: um harness que nao declarar `execution_policy: manual` e
  rejeitado no carregamento.
- Quatro harnesses curados: `data-scientist`, `statistician`,
  `package-maintainer` e `paper-author`.
- Adapter de referencia `claude` em `R/adapter_claude.R`: descoberta do
  binario, geracao de `settings.json` por mesclagem nao destrutiva, escrita do
  system prompt do papel no diretorio `.claude` do projeto e ligacao simbolica
  dos SKILL.md curados presentes no checkout do `community-skills`.
- Descoberta do `community-skills` por `COMMUNITY_SKILLS_PATH`,
  `~/.community-skills/` ou `~/projects/community-skills/`, sem embutir o
  catalogo no tarball.
- `clone_community_skills()` para obter o catalogo externo em um caminho
  discoverable, sem embuti-lo. Mensagem de carregamento indica o comando quando
  o catalogo nao e encontrado, sem acessar a rede no load.
- Lancamento via `rstudioapi::terminalCreate` quando dentro do RStudio, com
  recuo para emulador de terminal externo e, na ausencia deste, para reporte do
  comando ao usuario.
- Suite testthat com testes de fumaca dos quatro harnesses e do adapter
  `claude` com binario mockado e checkout de fixture.
