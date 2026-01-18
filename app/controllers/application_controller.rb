class ApplicationController < ActionController::API
  # NOTE: Clerk::Authenticatable uses helper_method which doesn't exist in API mode.
  # Instead, we access the Clerk session directly via request.env["clerk"]
  # which is set by the Clerk::RackMiddlewareV2

  before_action :authenticate_user!

  attr_reader :current_user

  private

  def clerk
    request.env["clerk"]
  end

  def authenticate_user!
    # clerk.user_id is provided by the Clerk middleware
    # It extracts the user ID from the session JWT automatically
    unless clerk&.user_id
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    @current_user = User.find_or_create_by!(clerk_id: clerk.user_id)
  rescue => e
    Rails.logger.error "Authentication error: #{e.message}"
    render json: { error: 'Authentication failed', details: e.message }, status: :unauthorized
  end
end
