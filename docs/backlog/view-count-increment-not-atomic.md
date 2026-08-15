# View count increment is not atomic

**Files:** `app/controllers/people_controller.rb:67-72`, `groups_controller.rb:97-102`,
`transfers_controller.rb:62-67`

`record.increment(:views); record.save` is a read-then-write with no lock. Concurrent requests
silently drop increments.

**Fix:** Replace with `record.increment!(:views)` (single SQL `UPDATE ... SET views = views + 1`)
or `record.update_counters(views: 1)`.
