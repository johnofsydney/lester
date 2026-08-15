# `Suggestion` model has no validations; controller uses `save` not `save!`

**Files:** `app/models/suggestion.rb`, `app/controllers/home_controller.rb:23`

The model is a single empty class body. The schema marks `headline` and `evidence` as NOT NULL,
but there are no AR validations — so a bad form submit either hits a DB constraint error (ugly
500) or silently ignores the failure.

**Fix:** Add `validates :headline, :evidence, presence: true`. Change `save` to `save!` or check
the result and render errors.
