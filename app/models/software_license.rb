class SoftwareLicense < ApplicationRecord
  belongs_to :asset

  validates :software_name, presence: true
  validates :expiration_date, presence: true

  def expired?
    expiration_date < Date.current
  end

  def days_until_expiration
    (expiration_date - Date.current).to_i
  end
end
