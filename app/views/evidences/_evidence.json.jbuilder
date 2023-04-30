json.extract! evidence, :id, :date_recorded, :summary, :link, :created_at, :updated_at
json.url evidence_url(evidence, format: :json)
