# API + Separate React Frontend — Design Plan

## What we're doing

Expose the Rails monolith as a JSON API so that one or more React frontends — each in their own repo, at their own URL, for their own audience — can consume the same data. The existing HTML app (join-the-dots.info) keeps working unchanged.

Auth is out of scope for now.

---

## Backend changes (this repo)

### 1. Add a versioned API namespace

Add `/api/v1/` routes alongside the existing HTML routes. Same app, same DB, same cache — just a different response format.

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :people,    only: %i[index show]
    resources :groups,    only: %i[index show]
    resources :transfers, only: %i[index show]
    get 'search',                      to: 'search#index'
    get 'people/:id/network_graph',    to: 'network_graphs#person'
    get 'groups/:id/network_graph',    to: 'network_graphs#group'
  end
end
```

### 2. API base controller

API controllers should skip the HTML-specific stack (CSRF, session, cookie auth, Phlex rendering). Use `ActionController::API` as the base, not `ActionController::Base`.

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
    # rate limiting here later; token auth here later
  end
end
```

### 3. Serialisers

The data is already in good shape inside `RehydratedNode`. We don't need a serialiser gem — plain Ruby methods that return hashes are enough.

**People and Groups:**
The `cached_summary` jsonb column already holds all the data the frontend needs. The API controller just needs to expose it cleanly:

```
GET /api/v1/people/:id
{
  "id": 1,
  "name": "scott morrison",
  "cache_fresh": true,            # if false, frontend should poll
  "money_in": 123456,
  "money_out": 0,
  "direct_connections": [...],
  "consolidated_transfers": [...],
  "top_six_as_giver": [...],
  "top_six_as_taker": [...]
}
```

**Network graph** — the serialisation already exists in `InertiaController#configure_node` and `#configure_edge`. Extract this into a shared concern or service, then call it from both the Inertia controller and the new API controller.

**Transfers:**
```
GET /api/v1/transfers/:id
{
  "id": 1,
  "giver": { "id": 1, "type": "Person", "name": "...", "url": "/people/1" },
  "taker": { "id": 2, "type": "Group",  "name": "...", "url": "/groups/2" },
  "amount": 50000,
  "effective_date": "2022-07-01",
  "transfer_type": "donations",
  "evidence": "https://..."
}
```

**Search:**
```
GET /api/v1/search?query=murdoch
{
  "results": [
    { "id": 5, "type": "Person", "name": "rupert murdoch", "url": "/people/5" },
    { "id": 12, "type": "Group", "name": "news corp australia", "url": "/groups/12" }
  ]
}
```

### 4. Cache-miss handling

Currently the HTML controllers render a "please refresh later" page. The API equivalent is an HTTP `202 Accepted` with a retry hint:

```json
{ "status": "building", "retry_after_seconds": 30 }
```

The API controller triggers the cache job (same as now) and returns 202. The frontend polls — simple.

### 5. CORS

Add `rack-cors` to the Gemfile. Allow GET requests from any registered frontend origin.

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:5173').split(',')
    resource '/api/*', headers: :any, methods: [:get]
  end
end
```

`ALLOWED_ORIGINS` in production is set via Hatchbox env vars — one comma-separated list covering all deployed frontend URLs.

### 6. Pagination

Return page metadata alongside results:

```json
{
  "data": [...],
  "meta": { "page": 0, "pages": 12, "total": 2847 }
}
```

### 7. Rate limiting

The existing rate limit (`Constants::CONTROLLER_RATE_LIMIT`) is per-IP, using `ActionController`'s built-in rate limiting. The API base controller gets the same limit, or a tighter one since API calls are cheaper to make in bulk.

---

## React frontend (new repo)

### Repo name suggestion: `join-the-dots-web`

### Stack
- Vite + React 18
- React Router v7 for routing
- TanStack Query for data fetching + caching + polling (handles the 202 retry loop cleanly)
- The `vis-network` graph library is already used in the existing `NetworkGraph.jsx` — copy and adapt it

### Pages
| Route | Component | API endpoint |
|-------|-----------|-------------|
| `/` | Search | `GET /api/v1/search?query=` |
| `/people` | PeopleIndex | `GET /api/v1/people` |
| `/people/:id` | PersonDetail | `GET /api/v1/people/:id` |
| `/people/:id/network` | NetworkGraph | `GET /api/v1/people/:id/network_graph` |
| `/groups` | GroupsIndex | `GET /api/v1/groups` |
| `/groups/:id` | GroupDetail | `GET /api/v1/groups/:id` |
| `/groups/:id/network` | NetworkGraph | `GET /api/v1/groups/:id/network_graph` |
| `/transfers` | TransfersIndex | `GET /api/v1/transfers` |
| `/transfers/:id` | TransferDetail | `GET /api/v1/transfers/:id` |

### Key components
- `SearchBox` — autocomplete on keystroke, debounced, calls search endpoint
- `MoneyBar` — horizontal bar chart for top-six givers/takers (replaces Bootstrap chart)
- `NetworkGraph` — vis-network canvas, lifted from existing `NetworkGraph.jsx`
- `TransferTable` — paginated table of transfers
- `CacheBuilding` — shown when API returns 202; polls until fresh

### "Different audiences" model

Each audience gets its own deployed instance of the React frontend (or a separate codebase) pointing at the same Rails API:

| Audience | URL | Difference |
|----------|-----|------------|
| General public | `join-the-dots.info` (existing HTML, unchanged) | Current Phlex/Bootstrap site |
| Journalists / researchers | `app.join-the-dots.info` | Richer React UI, more detail |
| Future: embeds | `embed.join-the-dots.info` | Single-entity widget, no nav |

The API namespace makes all of this possible without duplicating backend code. When auth lands, the API base controller gains a token check; different audiences can get different scopes.

---

## What stays the same

- The existing Phlex/Bootstrap HTML site at `join-the-dots.info` — untouched
- All Sidekiq jobs, ingestion pipelines, admin, ActiveAdmin
- The Inertia/React network graph on the existing site
- The DB schema

---

## Implementation order

### Phase 1 — API scaffold (backend only, ~1 day)
1. Add `rack-cors` gem, configure CORS
2. Create `Api::BaseController`
3. Add API routes
4. Implement `Api::V1::PeopleController` (index + show) with JSON
5. Implement `Api::V1::GroupsController` (index + show)
6. Implement `Api::V1::TransfersController` (index + show)
7. Implement `Api::V1::SearchController`
8. Implement `Api::V1::NetworkGraphsController` — extract node/edge serialisation from `InertiaController`
9. Handle 202 cache-miss response

### Phase 2 — New React frontend repo (~2–3 days)
1. `npm create vite@latest join-the-dots-web -- --template react`
2. Add React Router, TanStack Query
3. Set `VITE_API_BASE_URL` env var pointing at the Rails API
4. Implement Search page
5. Implement Person detail page
6. Implement Group detail page
7. Implement NetworkGraph page (port from existing `NetworkGraph.jsx`)
8. Implement Transfers pages
9. Deploy (Vercel, Netlify, or Hatchbox static)

### Phase 3 — Auth (later)
- API base controller gets token validation
- Frontend gets login flow
- Scoped endpoints per audience

---

## Open questions to decide before building

1. **Should the network graph endpoint live at `/api/v1/people/:id/network_graph` (separate endpoint) or just be included in the person show response?** Separate is cleaner — the network data is expensive and not needed on the detail page.

2. **What URL does the new React frontend get?** This drives the CORS config. Suggest `app.join-the-dots.info` or `explore.join-the-dots.info`.

3. **Should the frontend hit the API directly, or via a reverse proxy on the same domain (to avoid CORS entirely)?** Same domain via reverse proxy (Nginx rewrite `/api/` to the Rails app) avoids CORS complexity, but a separate domain is simpler to deploy. Worth deciding early.
