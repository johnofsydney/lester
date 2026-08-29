module Api
  # Base for JSON API controllers. Deliberately skips the HTML stack
  # (CSRF, session, cookie auth, Phlex rendering) that ApplicationController carries.
  # See docs/plans/0003-api-frontend-plan.md for the full design.
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
  end
end
