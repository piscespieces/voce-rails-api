class Note < ApplicationRecord
  belongs_to :user
  belongs_to :webhook, optional: true
  has_one_attached :audio_file
end
