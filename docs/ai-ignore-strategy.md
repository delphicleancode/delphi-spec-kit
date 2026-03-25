# AI Ignore Strategy — Delphi Spec Kit

> Defines which files and folders should be **excluded** from AI context/indexing, and which must be **preserved**.

## Layered Approach

The strategy is applied in three complementary layers:

| Layer | File | Scope |
|-------|------|-------|
| **Universal** | `.gitignore` | All tools; prevents tracking of binaries, build artifacts and sensitive files |
| **IDE / Workspace** | `.vscode/settings.json` | `files.exclude` and `search.exclude` reduce noise in VS Code navigation and search |
| **Cursor-specific** | `.cursorignore` | Prevents Cursor AI from indexing heavy/irrelevant paths |
| **Instruction-based** | `AGENTS.md`, `.github/copilot-instructions.md` | Tells AI agents explicitly what context to use and what to skip |

## What to Exclude (all layers)

### Delphi Build Artifacts
- `*.dcu`, `*.exe`, `*.dll`, `*.bpl`, `*.dcp`, `*.drc`, `*.map`, `*.obj`, `*.o`, `*.a`, `*.res`

### IDE Temporary Files
- `*.local`, `*.identcache`, `*.stat`, `*.~*`, `*.tvsconfig`, `__history/`, `__recovery/`

### Build / Output Directories
- `Win32/`, `Win64/`, `x64/`, `x86/`, `Debug/`, `Release/`, `build/`, `dist/`, `output/`

### Dependencies and Package Caches
- `node_modules/`, `.venv/`, `.pytest_cache/`, `.mypy_cache/`, `modules/`

### Sensitive / Credential Files
- `*.key`, `*.pfx`, `*.p12`, `.env`, `.env.*`

### Large / Noisy Files
- `*.log`, `*.dmp`, `*.bak`, `*.tmp`

## What to Preserve (NEVER exclude)

These files are essential for AI context and must always remain indexed and accessible:

| File / Path | Reason |
|-------------|--------|
| `AGENTS.md` | Universal rules for all AI agents |
| `README.md` | Project overview and quick start |
| `.github/copilot-instructions.md` | Copilot pre-prompt |
| `.claude/CLAUDE.md` | Claude master prompt |
| `.claude/rules/**/*.md` | Context-specific rules |
| `.claude/skills/**/SKILL.md` | On-demand skill files |
| `.cursor/rules/**/*.md` | Cursor rules |
| `.gemini/skills/**/SKILL.md` | Gemini skills |
| `.kiro/steering/**/*.md` | Kiro steering docs |
| `examples/**/*.pas` | Good practice examples |
| `docs/**/*.md` | Documentation |

## Tool-Specific Support Matrix

| AI Tool | Dedicated Ignore File | Behavior |
|---------|----------------------|----------|
| **Cursor** | `.cursorignore` | Explicit ignore for indexing and context |
| **Claude Code** | N/A | Uses rules/instructions; respects `.gitignore` and workspace excludes |
| **GitHub Copilot** | N/A | Follows `files.exclude`, `search.exclude`, `.gitignore` and instruction files |
| **Gemini / Antigravity** | N/A | Follows workspace structure and `.gitignore` |
| **Kiro** | N/A | Follows workspace structure and `.gitignore` |

## Maintenance Checklist

When adding new modules or subprojects:

- [ ] Verify build output folders are covered by `.gitignore`
- [ ] Verify `.cursorignore` includes any new heavy/binary paths
- [ ] Verify essential instruction files are NOT excluded
- [ ] Verify `.vscode/settings.json` excludes are up to date
