class WebhooksController < ApplicationController
  before_action :set_webhook, only: [:update, :destroy]

  def index
    @webhooks = @current_user.webhooks.order(created_at: :desc)
    render json: @webhooks
  end

  def create
    @webhook = @current_user.webhooks.new(webhook_params)

    if @webhook.save
      render json: @webhook, status: :created
    else
      render json: @webhook.errors, status: :unprocessable_entity
    end
  end

  def update
    if @webhook.update(webhook_params)
      render json: @webhook
    else
      render json: @webhook.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @webhook.destroy
  end

  def test
    url = params[:url]
    headers_param = params[:headers] || {}

    # Basic validation
    unless url.present? && (url.start_with?('http://') || url.start_with?('https://'))
      return render json: { success: false, error: "Invalid URL" }, status: :bad_request
    end

    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Post.new(uri.path.presence || '/', { 'Content-Type' => 'application/json' })

      # Add custom headers
      headers_param.each do |key, value|
        request[key] = value
      end

      request.body = {
        event: "test_ping",
        timestamp: Time.current.iso8601,
        message: "This is a test request from Voce."
      }.to_json

      response = http.request(request)

      if response.code.to_i >= 200 && response.code.to_i < 300
        render json: { success: true, code: response.code }
      else
        render json: { success: false, code: response.code, error: "Remote server returned error" }, status: :bad_request
      end
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :bad_request
    end
  end

  private

  def set_webhook
    @webhook = @current_user.webhooks.find(params[:id])
  end

  def webhook_params
    params.require(:webhook).permit(:name, :url, :active, headers: {})
  end
end
