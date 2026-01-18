class ProfileController < ApplicationController
  def show
    # Fetch user data from Clerk using the clerk_id
    # clerk.user makes a request to Clerk API and returns the user object
    clerk_user = clerk.user

    render json: {
      email: clerk_user&.dig("email_addresses", 0, "email_address"),
      notes_count: @current_user.notes.count
    }
  end
end
