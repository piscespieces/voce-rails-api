class NotesController < ApplicationController
  def index
    notes = @current_user.notes.order(created_at: :desc).map do |note|
      {
        id: note.id,
        title: note.title || "Untitled Note",
        content: note.content,
        status: note.status,
        created_at: note.created_at,
        duration: format_duration(note.duration)
      }
    end
    render json: notes
  end


  def show
    note = @current_user.notes.find(params[:id])
    render json: note
  end

  def create
    note = @current_user.notes.build(note_params)

    if note.save
      # Enqueue transcription job if audio file is attached
      TranscribeAudioJob.perform_async(note.id) if note.audio_file.attached?

      render json: note, status: :created
    else
      render json: { errors: note.errors }, status: :unprocessable_entity
    end
  end

  def update
    note = @current_user.notes.find(params[:id])

    if note.update(note_params)
      render json: note
    else
      render json: { errors: note.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    note = @current_user.notes.find(params[:id])
    note.destroy
    head :no_content
    # Or render json: { message: "Note deleted" } if preferred, but head :no_content is standard
  end


  def forward
    note = @current_user.notes.find(params[:id])
    webhook_id = params[:webhook_id] || note.webhook_id

    unless webhook_id
      return render json: { error: "No webhook selected" }, status: :unprocessable_entity
    end

    webhook = @current_user.webhooks.find_by(id: webhook_id)
    unless webhook
       return render json: { error: "Webhook not found" }, status: :not_found
    end

    begin
        uri = URI.parse(webhook.url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 5
        http.read_timeout = 10

        request = Net::HTTP::Post.new(uri.path.presence || '/', { 'Content-Type' => 'application/json' })

        # Merge headers
        if webhook.headers.is_a?(Hash)
            webhook.headers.each do |key, value|
                request[key] = value
            end
        end

        payload = note.as_json
        request.body = payload.to_json

        response = http.request(request)

        if response.code.to_i >= 200 && response.code.to_i < 300
            render json: { success: true, code: response.code }
        else
            render json: { success: false, code: response.code, error: "Remote webhook returned error" }, status: :bad_request
        end
    rescue StandardError => e
        render json: { success: false, error: e.message }, status: :bad_request
    end
  end

  private

  def note_params
    params.require(:note).permit(:title, :content, :status, :webhook_id, :audio_file, :duration)
  end

  def format_duration(seconds)
    return "0:00" unless seconds
    "%d:%02d" % [seconds / 60, seconds % 60]
  end
end
