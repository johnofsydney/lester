# Rails derives the session cookie name from the app's module name only, so
# every git worktree of this app (e.g. for parallel feature branches) shares
# one cookie. Browser cookies aren't port-scoped, so two worktrees running on
# different localhost ports stomp on each other's session/CSRF state. Scoping
# the key to the worktree directory name gives each one its own cookie.
Rails.application.config.session_store :cookie_store, key: "_sunshine01_session_#{Rails.root.basename}"
