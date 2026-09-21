---
name: local-iteration
description: Review the in-progress change with parallel subagents, fix what they find, and repeat until clean. Use when the user asks to iterate on, harden, polish, or "review and fix" the current change before committing or opening a PR.
---

# Local iteration

A review-and-fix loop over the change currently being worked on. Up to 5
iterations. Each iteration runs up to 5 review subagents in parallel, then you
apply the fixes yourself.

## Scope the change

Before iterating, establish the diff under review, in this order:

1. Uncommitted work: `git status` plus `git diff HEAD`.
2. Nothing uncommitted: the branch's commits against the main branch.
3. Neither: ask what to review. Do not guess.

State the scope in one line before the first iteration.

## The loop

Each iteration:

1. **Review.** Spawn up to 5 subagents in a single message so they run in
   parallel. Give each one the scope and a distinct lens (see below). They are
   read-only: they report findings, they do not edit. Use fewer than 5 when the
   change is small enough that extra lenses would overlap.
2. **Triage.** Merge the findings, drop duplicates, and discard anything you can
   verify is wrong — subagents report plausible-sounding non-issues, so check a
   claim against the code before acting on it. Sort what survives into major and
   minor.
3. **Fix.** Apply the major findings. Fix minor ones only when the fix is
   trivial and touches code already in the diff. Run the project's tests and
   linter after editing.
4. **Report.** One or two lines: what was found, what was fixed, what was
   dismissed and why.

Then start the next iteration against the updated diff.

## Review lenses

Pick the lenses that fit the change; one subagent each.

- **Correctness** — logic errors, edge cases, off-by-one, nil/empty/error paths.
- **Integration** — callers and call sites the change breaks; stale docs,
  comments, and config that referenced the old behavior.
- **Tests** — new behavior without coverage, tests asserting the wrong thing,
  tests that pass regardless of the change.
- **Security and data safety** — injection, unvalidated input, leaked secrets,
  destructive or irreversible operations, permission and auth gaps.
- **Design fit** — does this match how the surrounding code already solves this
  problem; duplicated logic, wrong abstraction level, needless complexity.

## Major vs minor

**Major:** wrong output, crash, data loss, security hole, broken caller,
contract or API break, meaningful performance regression, new behavior with no
test.

**Minor:** naming, comment wording, formatting, speculative refactors,
preferences unsupported by the surrounding code. These do not keep the loop
running.

## Stopping

Stop as soon as an iteration's review turns up no major issues — that is the
goal, not a failure to reach 5. Otherwise stop after the 5th iteration.

Also stop early and say so when findings start repeating without the code
changing, or when a finding needs a decision only the user can make. Do not
invent work to fill remaining iterations.

## Finishing

Close with a short summary: iterations run, major issues fixed, anything
deliberately left alone, and the state of tests and lint. If you stopped at the
iteration cap with major issues outstanding, say that plainly and list them.
