# claude-handoff

Custom slash commands for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that capture session context into a structured `HANDOFF.md` file — so you can resume an interrupted fix in a new session with no information loss.

## Commands

| Command | Description |
|---|---|
| `/handoff` | Creates a new `HANDOFF.md` from scratch in the repo root |
| `/handoff-update` | Updates an existing `HANDOFF.md` without losing history |

Both commands automatically run `git diff`, `git status`, and `git log` to collect context, then print the **Resume Prompt** directly in the terminal for you to paste into the next session.

## Installation

### Option 1 — install script (global)

```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/claude-handoff/main/install.sh | bash
```

This installs the commands to `~/.claude/commands/`, making them available in every project.

### Option 2 — manual (global)

```bash
mkdir -p ~/.claude/commands

curl -o ~/.claude/commands/handoff.md \
  https://raw.githubusercontent.com/seu-usuario/claude-handoff/main/.claude/commands/handoff.md

curl -o ~/.claude/commands/handoff-update.md \
  https://raw.githubusercontent.com/seu-usuario/claude-handoff/main/.claude/commands/handoff-update.md
```

### Option 3 — per project

Clone or copy the `.claude/commands/` folder into your project root:

```bash
mkdir -p .claude/commands

curl -o .claude/commands/handoff.md \
  https://raw.githubusercontent.com/seu-usuario/claude-handoff/main/.claude/commands/handoff.md

curl -o .claude/commands/handoff-update.md \
  https://raw.githubusercontent.com/seu-usuario/claude-handoff/main/.claude/commands/handoff-update.md
```

> Commands in `.claude/commands/` are scoped to that project only.
> Commands in `~/.claude/commands/` are available globally.

## Usage

Inside a Claude Code session, when you need to pause or are running low on tokens:

```
/handoff
```

This creates `HANDOFF.md` and prints a Resume Prompt at the end. Copy that prompt and paste it as the first message in a new session.

To update the file mid-session after making more progress:

```
/handoff-update
```

This preserves the history of attempted approaches and known facts, and rewrites only what changed.

## What gets captured

```
HANDOFF.md
├── Goal             — what needs to be solved
├── Current State    — exact point of interruption
├── Key Files        — files modified or relevant
├── Already Tried    — approaches and their outcomes
├── Known Facts      — confirmed and ruled-out hypotheses
├── Blockers         — what is preventing completion
├── Next Steps       — ordered concrete actions
└── Resume Prompt    — self-contained prompt for the next session
```

## Customizing the template

The structure of the generated `HANDOFF.md` is defined in `.claude/commands/handoff-template.md`.
Edit that file to add, remove, or rename sections — both commands pick up the changes
automatically without touching the command logic.

For example, to add an **Environment** section, open `handoff-template.md` and add:

```markdown
## Environment

{{Node version, OS, Docker, env vars, or anything else relevant to reproduce the issue.}}
```

## Repository structure

```
claude-handoff/
├── .claude/
│   └── commands/
│       ├── handoff.md           # /handoff command — logic only
│       ├── handoff-update.md    # /handoff-update command — logic only
│       └── handoff-template.md  # output structure — edit this to customize
├── install.sh                   # global install script
└── README.md
```

## How Claude Code slash commands work

Claude Code reads `.md` files from two locations and exposes them as `/command-name`:

- `~/.claude/commands/` — global, available in all projects
- `.claude/commands/` — local, available in that project only

The filename becomes the command name: `handoff.md` → `/handoff`.

The file content is the instruction sent to Claude when the command is invoked.

## License

MIT