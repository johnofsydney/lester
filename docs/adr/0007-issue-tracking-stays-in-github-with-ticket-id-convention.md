# Issue tracking stays in GitHub Issues, with an LES-\<number\> ticket-ID convention

**Status:** Accepted

## Context

Raised in [#282](https://github.com/johnofsydney/lester/issues/282): as a solo developer now
managing several AI agents at once, John felt more like an engineering manager than a single
developer, and asked whether an external ticketing system (Linear, Jira, etc.) would help track
requirements/status and let agents pick up work more cleanly -- or whether GitHub Issues already
covers it.

The real pain point, surfaced in discussion, wasn't the platform: issues had been used as loose
backlog notes rather than single closeable units of work, which made them hard to close out
cleanly. Any change also had to satisfy a hard constraint: increase throughput, and do not
increase human complexity for John.

## Decision

Keep GitHub Issues as the single source of truth for requirements and status. Do not adopt an
external ticketing tool. Two changes instead:

1. **Split broad issues into sub-issues** (GitHub's native parent/child issue support) so each
   sub-issue maps to one mergeable PR and can close cleanly on merge, rather than staying open as
   a loose topic.
2. **Adopt a `LES-<number>` ticket-ID convention**, reusing the existing GitHub issue number (e.g.
   `LES-282` for issue #282), for reference in commit messages, branch names, and PR titles. This
   is purely a display/reference convention over GitHub's existing unique, sequential
   per-repo issue numbering -- no separate numbering system to maintain or keep in sync.

This keeps agents and John working out of one system that's already wired up (`gh` CLI, GitHub
MCP tools), satisfying "don't increase human complexity" by avoiding a second tool to sync issue
state against.

## Consequence

`docs/agents/issue-tracker.md` (or wherever issue-tracking guidance lives) should mention the
`LES-` prefix convention and the preference for sub-issues over monolithic issues going forward.
