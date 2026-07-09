class Asset < ApplicationRecord
  ASSET_TYPES = %w[
    server
    workstation
    network_device
    printer
    mobile_device
  ].freeze

  belongs_to :company

  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: ASSET_TYPES }
  validates :serial_number, uniqueness: true, allow_blank: true
end
