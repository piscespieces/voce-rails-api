class User < ApplicationRecord
  has_many :notes, dependent: :destroy
  has_many :webhooks, dependent: :destroy
end
