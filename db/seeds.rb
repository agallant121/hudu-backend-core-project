# Demo data for manually checking the five API endpoints.
#
# FactoryBot is intentionally not used here: it is loaded only in development/test,
# and seeds should be idempotent so `rails db:seed` can be run more than once.
# These helpers create stable records by natural lookup fields and update the
# important attributes when the seed already exists.

today = Date.current
now = Time.current

def seed_record(model, lookup, attributes = {})
  record = model.find_or_initialize_by(lookup)
  record.assign_attributes(attributes)
  record.save!
  record
end

def seed_company(name:, city:, state:)
  seed_record(Company, { name: }, city:, state:)
end

def seed_user(email:, name:)
  seed_record(User, { email: }, name:)
end

def seed_contact(company:, email:, name:, role:)
  seed_record(Contact, { company:, email: }, name:, role:)
end

def seed_asset(company:, serial_number:, name:, asset_type:, purchase_date:)
  seed_record(
    Asset,
    { serial_number: },
    company:,
    name:,
    asset_type:,
    purchase_date:
  )
end

def seed_maintenance(asset:, description:, performed_at:, cost:)
  seed_record(
    MaintenanceRecord,
    { asset:, description:, performed_at: },
    cost:
  )
end

def seed_license(asset:, software_name:, license_key:, expiration_date:)
  seed_record(
    SoftwareLicense,
    { asset:, software_name:, license_key: },
    expiration_date:
  )
end

def seed_note(asset:, author:, content:, created_at:)
  seed_record(
    Note,
    { asset:, content: },
    author:,
    created_at:
  )
end

# Companies give the dashboard and comparison endpoints multiple tenants to
# aggregate and filter across.
acme = seed_company(name: "Seed Acme Corp", city: "Denver", state: "CO")
beta = seed_company(name: "Seed Beta LLC", city: "Austin", state: "TX")
quiet = seed_company(name: "Seed Quiet Co", city: "Portland", state: "OR")

# Contacts exercise primary-contact selection and fallback behavior.
seed_contact(
  company: acme,
  name: "Priya Primary",
  email: "seed-primary@acme.example",
  role: Contact::PRIMARY_ROLE
)
seed_contact(
  company: acme,
  name: "Terry Technical",
  email: "seed-tech@acme.example",
  role: "technical"
)
seed_contact(
  company: beta,
  name: "Bill Billing",
  email: "seed-billing@beta.example",
  role: "billing"
)
# Quiet Co intentionally has no contacts so nil contact responses are easy to check.

author = seed_user(email: "seed-notes@example.com", name: "Seed Notes Author")

# Assets cover grouping by company and asset type.
acme_server = seed_asset(
  company: acme,
  serial_number: "SEED-ACME-SRV-001",
  name: "SEED-ACME-SERVER-01",
  asset_type: "server",
  purchase_date: today - 3.years
)
acme_workstation = seed_asset(
  company: acme,
  serial_number: "SEED-ACME-WKS-001",
  name: "SEED-ACME-WORKSTATION-01",
  asset_type: "workstation",
  purchase_date: today - 18.months
)
acme_printer = seed_asset(
  company: acme,
  serial_number: "SEED-ACME-PRN-001",
  name: "SEED-ACME-PRINTER-01",
  asset_type: "printer",
  purchase_date: today - 2.years
)
beta_server = seed_asset(
  company: beta,
  serial_number: "SEED-BETA-SRV-001",
  name: "SEED-BETA-SERVER-01",
  asset_type: "server",
  purchase_date: today - 1.year
)
quiet_asset = seed_asset(
  company: quiet,
  serial_number: "SEED-QUIET-WKS-001",
  name: "SEED-QUIET-WORKSTATION-01",
  asset_type: "workstation",
  purchase_date: today - 6.months
)

# Maintenance records exercise YTD totals, recent-maintenance ordering, and
# date-range reports. One previous-year record proves old costs are excluded
# from YTD dashboard and comparison totals.
seed_maintenance(
  asset: acme_server,
  description: "Seed replaced RAID battery",
  performed_at: now - 4.days,
  cost: 325.50
)
seed_maintenance(
  asset: acme_workstation,
  description: "Seed upgraded workstation memory",
  performed_at: now - 3.days,
  cost: 180.00
)
seed_maintenance(
  asset: acme_printer,
  description: "Seed printer roller kit",
  performed_at: now - 2.days,
  cost: 95.25
)
seed_maintenance(
  asset: beta_server,
  description: "Seed patched hypervisor",
  performed_at: now - 1.day,
  cost: 240.75
)
seed_maintenance(
  asset: acme_server,
  description: "Seed previous-year server service",
  performed_at: now.prev_year,
  cost: 999.99
)

# Software licenses cover expired, currently expiring, boundary, and excluded
# future licenses for dashboard, comparison, and expiring-license reports.
seed_license(
  asset: acme_server,
  software_name: "Seed Backup Suite",
  license_key: "SEED-BACKUP-EXPIRED",
  expiration_date: today - 10.days
)
seed_license(
  asset: acme_server,
  software_name: "Seed Monitoring Pro",
  license_key: "SEED-MONITORING-TODAY",
  expiration_date: today
)
seed_license(
  asset: acme_workstation,
  software_name: "Seed Office Suite",
  license_key: "SEED-OFFICE-30",
  expiration_date: today + 30.days
)
seed_license(
  asset: beta_server,
  software_name: "Seed Endpoint Security",
  license_key: "SEED-ENDPOINT-60",
  expiration_date: today + 60.days
)
seed_license(
  asset: acme_printer,
  software_name: "Seed Print Manager",
  license_key: "SEED-PRINT-90",
  expiration_date: today + 90.days
)

# Notes make the asset detail endpoint show recent activity and author loading.
12.times do |index|
  seed_note(
    asset: acme_server,
    author:,
    content: "Seed asset detail note #{index + 1}",
    created_at: now - index.hours
  )
end

puts "Seed data ready."
puts "Dashboard:          GET /api/v1/companies/#{acme.id}/dashboard"
puts "Asset detail:       GET /api/v1/assets/#{acme_server.id}"
puts "Company comparison: GET /api/v1/reports/company_comparison?company_ids[]=#{acme.id}&company_ids[]=#{beta.id}&company_ids[]=#{quiet.id}"
puts "Expiring licenses:  GET /api/v1/reports/expiring_licenses"
puts "Maintenance costs:  GET /api/v1/reports/maintenance_costs?start_date=#{today.beginning_of_year.iso8601}&end_date=#{today.iso8601}"
