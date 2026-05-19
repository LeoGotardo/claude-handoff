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

## Step 2 — Write HANDOFF.md

Write the file to the repo root. Follow this exact structure:

```markdown
# Handoff File

**Project:** <repo name from remote URL or folder name>
**Branch:** <current branch>
**Date:** <today YYYY-MM-DD>
**Status:** paused / interrupted

---

## Goal

<What the user originally asked to fix or build. Expected behavior vs current behavior. What "done" looks like.>

---

## Current State

<Last completed action. What is partially done. Exact point of interruption — be specific about file and line if relevant.>

---

## Key Files

<Files modified (from git diff) + files discussed in this session. One line per file with reason.>

1. `path/to/file` — reason
2. `path/to/file` — reason

---

## Already Tried

<Every approach attempted and its outcome. Be specific: what failed and why.>

1. Tried X → result was Y
2. Tried X → result was Y

---

## Known Facts

<Confirmed root causes, ruled-out hypotheses, relevant error messages or stack traces.>

- confirmed: ...
- ruled out: ...

---

## Blockers

<What is preventing completion. If nothing, write N/A.>

---

## Next Steps

<Ordered concrete actions to complete the fix. Name the exact file, function, or command for each step.>

1. action — `file:line` or `$ command`
2. action — `file:line` or `$ command`
3. action — `file:line` or `$ command`

---

## Resume Prompt

<Write the exact first message to paste into a new Claude Code session. Must be fully self-contained — no references to "the previous session". Include: what is being fixed, current state, what to do next, and any constraints (e.g. "do not change X").>
```

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