class Contact < ApplicationRecord
  PRIMARY_ROLE = "primary"
  ROLES = %w[
    primary
    technical
    billing
  ].freeze

  belongs_to :company

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
end
