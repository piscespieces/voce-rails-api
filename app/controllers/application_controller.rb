class ApplicationController < ActionController::API
  include Clerk::Authenticatable

  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    if clerk.session.nil?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    # clerk.session is the claims hash from the verifying the token
    # 'sub' is the Subject (User ID)
    user_clerk_id = clerk.session['sub']

    @current_user = User.find_or_create_by!(clerk_id: user_clerk_id)
  rescue StandardError => e
    Rails.logger.error "Authentication error: #{e.message}"
    render json: { error: 'Authentication failed' }, status: :unauthorized
  end
end
