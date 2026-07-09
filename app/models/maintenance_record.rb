class MaintenanceRecord < ApplicationRecord
  belongs_to :asset

  validates :description, presence: true
  validates :performed_at, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
