Resume work from an existing HANDOFF.md file. Read the full context, confirm your understanding, and continue the fix without asking the user to re-explain anything.

## Step 1 — Find and read the handoff file

```bash
cat HANDOFF.md 2>/dev/null || find . -name "HANDOFF.md" -not -path "*/node_modules/*" | head -1 | xargs cat 2>/dev/null
```

If no HANDOFF.md is found, stop and say:
"No HANDOFF.md found in this project. Run /handoff in your previous session to create one first."

## Step 2 — Read the current repo state

Run silently to understand what has changed since the handoff was written:

```bash
git branch --show-current
git diff --name-only
git status --short
git log --oneline -5
```

## Step 3 — Cross-reference

Compare the handoff file against the current repo state:

- Are the Key Files still in the state described, or have they changed?
- Do any Next Steps appear to already be done based on git diff or git log?
- Are there new uncommitted changes not mentioned in the handoff?

Note any discrepancies — do not silently skip them.

## Step 4 — Output a catchup summary

Print a structured summary in this exact format:

```
HANDOFF CATCHUP
───────────────────────────────────────────────────────────────────────────────

GOAL
<one sentence restatement of what needs to be solved>

CURRENT STATE
<what was done, what is partial, what is broken — updated with any repo changes found>

WHAT I KNOW
<key confirmed facts and ruled-out hypotheses from the handoff>

BLOCKERS
<active blockers, or "none" if resolved>

STARTING FROM
<the first Next Step from the handoff that is not yet done, with file and action>

───────────────────────────────────────────────────────────────────────────────
Ready. Starting on: <first action>
```

## Step 5 — Begin immediately

Do not ask "should I proceed?" or "do you want me to continue?".
Start executing the first Next Step from the handoff right away.

If the first step is ambiguous, make a reasonable interpretation, state it in one line, and proceed.