# frozen_string_literal: true

class TranscribeAudioJob
  include Sidekiq::Job

  sidekiq_options retry: 3, queue: "default"

  def perform(note_id)
    note = Note.find_by(id: note_id)
    return unless note
    return unless note.audio_file.attached?

    begin
      # Call ElevenLabs API for transcription
      service = ElevenlabsSttService.new
      result = service.create_transcript(note.audio_file)

      # Update note with transcript
      transcript_text = result["text"] || result.dig("transcription", "text")

      note.update!(
        content: transcript_text,
        title: generate_title(transcript_text),
        status: "completed"
      )

      Rails.logger.info "[TranscribeAudioJob] Note #{note_id} transcribed successfully"

    rescue ElevenlabsSttService::TranscriptionError => e
      Rails.logger.error "[TranscribeAudioJob] Transcription failed for note #{note_id}: #{e.message}"
      note.update!(status: "failed")

    rescue StandardError => e
      Rails.logger.error "[TranscribeAudioJob] Unexpected error for note #{note_id}: #{e.message}"
      note.update!(status: "failed")
      raise # Re-raise to trigger Sidekiq retry
    end
  end

  private

  def generate_title(transcript_text)
    return "Untitled Note" if transcript_text.blank?

    # Take first 50 chars or first sentence, whichever is shorter
    first_sentence = transcript_text.split(/[.!?]/).first&.strip
    title = first_sentence || transcript_text

    title.truncate(50)
  end
end
