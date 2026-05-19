Create a HANDOFF.md file that captures the full context of this session so a new Claude Code session can resume immediately with no information loss.

## Step 1 — Collect context automatically

Run the following commands silently to gather repo state:

```bash
git branch --show-current
git remote get-url origin 2>/dev/null || echo "no remote"
git diff --name-only
git diff --stat
git log --oneline -10
git status --short
```

Do NOT ask the user for information you can derive from the conversation history or from the commands above.

## Step 2 — Load the template

Read the template file:

```bash
cat .claude/commands/handoff-template.md
```

Use that structure to write HANDOFF.md to the repo root. Replace every `{{PLACEHOLDER}}`
with real content derived from the conversation and git output above.

- `{{PROJECT}}` — repo name from remote URL or folder name
- `{{BRANCH}}` — current branch
- `{{DATE}}` — today in YYYY-MM-DD format
- All other `{{...}}` fields — fill with session context

Rules:
- Be specific. Vague entries like "fix auth" are not acceptable.
- Every Next Step must name a concrete file, function, or command.
- The Resume Prompt must work standalone — assume the reader has zero prior context.
- Do not truncate any section. Write N/A if there is nothing to add.
- Keep the file under 150 lines so it fits in a new session's context window.

## Step 3 — Confirm and print Resume Prompt

After writing the file, output exactly this:

```
HANDOFF.md created.

── RESUME PROMPT ────────────────────────────────────────────────────────────

<paste the Resume Prompt section here>

─────────────────────────────────────────────────────────────────────────────

Paste the block above into a new Claude Code session to resume.
```