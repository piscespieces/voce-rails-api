# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

class ElevenlabsSttService
  BASE_URL = "https://api.elevenlabs.io/v1"
  DEFAULT_MODEL = "scribe_v2"

  class TranscriptionError < StandardError; end

  def initialize(api_key: nil)
    @api_key = api_key || ENV["ELEVENLABS_API_KEY"]
    raise ArgumentError, "ElevenLabs API key is required" if @api_key.blank?
  end

  # Create a transcript from an audio file
  # @param audio_file [ActiveStorage::Attached, File, IO] The audio file to transcribe
  # @param options [Hash] Optional parameters (language_code, diarize, etc.)
  # @return [Hash] The transcription response
  def create_transcript(audio_file, options = {})
    file_data = prepare_file_data(audio_file)

    payload = {
      file: Faraday::Multipart::FilePart.new(
        StringIO.new(file_data[:content]),
        file_data[:content_type],
        file_data[:filename]
      ),
      model_id: options.fetch(:model_id, DEFAULT_MODEL)
    }

    # Add optional parameters
    options.except(:model_id).each do |key, value|
      payload[key] = value
    end

    response = connection.post("/v1/speech-to-text", payload)
    handle_response(response)
  end

  # Get an existing transcript by ID
  # @param transcription_id [String] The transcript ID
  # @return [Hash] The transcript data
  def get_transcript(transcription_id)
    response = connection.get("/v1/speech-to-text/transcripts/#{transcription_id}")
    handle_response(response)
  end

  # Delete a transcript
  # @param transcription_id [String] The transcript ID to delete
  # @return [Boolean] true if successful
  def delete_transcript(transcription_id)
    response = connection.delete("/v1/speech-to-text/transcripts/#{transcription_id}")
    response.success?
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :multipart
      f.request :url_encoded
      f.headers["xi-api-key"] = @api_key
      f.options.timeout = 120 # Transcription can take a while
      f.options.open_timeout = 30
      f.adapter Faraday.default_adapter
    end
  end

  def prepare_file_data(audio_file)
    case audio_file
    when ActiveStorage::Attached::One
      {
        content: audio_file.download,
        filename: audio_file.filename.to_s,
        content_type: audio_file.content_type
      }
    when ActiveStorage::Blob
      {
        content: audio_file.download,
        filename: audio_file.filename.to_s,
        content_type: audio_file.content_type
      }
    when File, Tempfile
      {
        content: audio_file.read,
        filename: File.basename(audio_file.path),
        content_type: Marcel::MimeType.for(audio_file)
      }
    when ActionDispatch::Http::UploadedFile
      {
        content: audio_file.read,
        filename: audio_file.original_filename,
        content_type: audio_file.content_type
      }
    else
      raise ArgumentError, "Unsupported file type: #{audio_file.class}"
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      return true if response.body.blank?
      JSON.parse(response.body)
    when 401
      raise TranscriptionError, "Invalid API key"
    when 422
      error = JSON.parse(response.body) rescue {}
      raise TranscriptionError, "Validation error: #{error['detail'] || response.body}"
    when 429
      raise TranscriptionError, "Rate limit exceeded"
    else
      error = JSON.parse(response.body) rescue {}
      raise TranscriptionError, "API error (#{response.status}): #{error['detail'] || response.body}"
    end
  end
end
