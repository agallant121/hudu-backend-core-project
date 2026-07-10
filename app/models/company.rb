class Company < ApplicationRecord
  has_many :assets, dependent: :destroy
  has_many :contacts, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def primary_contact
    if contacts.loaded?
      contacts.find { |contact| contact.role == Contact::PRIMARY_ROLE } || contacts.min_by(&:id)
    else
      contacts.find_by(role: Contact::PRIMARY_ROLE) || contacts.order(:id).first
    end
  end
end
