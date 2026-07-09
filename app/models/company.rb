class Company < ApplicationRecord
  has_many :contacts, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def primary_contact
    contacts.find_by(role: Contact::PRIMARY_ROLE) || contacts.order(:id).first
  end
end
