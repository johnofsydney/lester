# Only Federal Branch Membership is closed by Interpretation; State Branch and Minor Party Membership stay open-ended

**Status:** Accepted

Interpretation sets an `end_date` on a Federal Branch Membership (and its Position) when the corresponding Parliament Membership ends — by retirement, losing a seat, or a party switch — because that date is knowable: federal branch membership tracks time in federal Parliament. State Branch Membership and Minor Party Membership are never closed by Interpretation, even on the same events, because OpenAustralia gives us no signal for when someone actually joined or left a state or minor party branch; they typically predate and outlast the person's time in Parliament. This asymmetry is deliberate, not an oversight — the first implementation attempt closed State Branch Membership the same way as Federal Branch Membership on two separate occasions during code review, each time reintroducing the bug this ADR exists to prevent.
