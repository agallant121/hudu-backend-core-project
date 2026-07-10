class User < ApplicationRecord
  has_many :notes, foreign_key: :author_id, inverse_of: :author

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
