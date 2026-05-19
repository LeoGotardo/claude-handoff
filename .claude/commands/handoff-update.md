Update the existing HANDOFF.md with the latest state of this session. Preserve what is still accurate, update what has changed, and sharpen the Next Steps.

## Step 1 — Read the existing file

```bash
cat HANDOFF.md
```

If HANDOFF.md does not exist, stop and say: "No HANDOFF.md found. Run /handoff to create one first."

## Step 2 — Collect current repo state

```bash
git branch --show-current
git diff --name-only
git diff --stat
git log --oneline -10
git status --short
```

## Step 3 — Load the template (for section reference)

```bash
cat .claude/commands/handoff-template.md
```

Use the section names from the template as the canonical structure when rewriting the file.

## Step 4 — Diff and update

Compare the existing file against the current session state. For each section, apply this logic:

| Section | Update rule |
|---|---|
| **Date** | Always update to today |
| **Status** | Update if it changed |
| **Goal** | Keep as-is unless the scope changed |
| **Current State** | Replace entirely with latest state |
| **Key Files** | Add new files touched since last handoff; keep existing ones |
| **Already Tried** | Append new attempts; never remove old ones |
| **Known Facts** | Append new findings; move disproven hypotheses to "ruled out" |
| **Blockers** | Replace with current blockers; remove resolved ones |
| **Next Steps** | Replace entirely with the updated ordered list |
| **Resume Prompt** | Rewrite entirely to reflect current state |

Rules:
- Never delete entries from Already Tried or Known Facts — they are a record.
- Next Steps must be rewritten from scratch — do not carry over completed steps.
- The Resume Prompt must always be fully rewritten. It must be self-contained and current.
- Keep the file under 150 lines.

## Step 5 — Write the updated file

Overwrite HANDOFF.md with the updated content.

## Step 6 — Confirm and print Resume Prompt

After writing, output exactly this:

```
HANDOFF.md updated.

── RESUME PROMPT ────────────────────────────────────────────────────────────

<paste the updated Resume Prompt section here>

─────────────────────────────────────────────────────────────────────────────

Paste the block above into a new Claude Code session to resume.
```