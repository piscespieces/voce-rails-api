class NotesController < ApplicationController
  def index
    notes = @current_user.notes.order(created_at: :desc)
    render json: notes
  end

  def create
    note = @current_user.notes.build(note_params)

    if note.save
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

  private

  def note_params
    params.require(:note).permit(:title, :content, :status, :webhook_id)
  end
end
