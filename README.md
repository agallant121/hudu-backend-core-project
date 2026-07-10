# IT Asset Inventory API

Rails API take-home project for managing IT assets across multiple client companies. The app models companies, assets, maintenance records, software licenses, contacts, notes, and users, then exposes dashboard and reporting endpoints for MSP-style asset inventory workflows.

## Tech Stack

- Ruby 3.4.2
- Rails 8.0.5
- PostgreSQL
- RSpec
- FactoryBot
- Bullet (development)

## Setup

Requirements:

- Ruby 3.4.2, matching `.ruby-version`
- Bundler version from `Gemfile.lock`
- PostgreSQL

Install dependencies:

```bash
bundle install
```

Set up the database and load demo data:

```bash
bin/rails db:setup
```

`db:setup` creates the database, loads the schema, and runs seeds. It does not drop an existing database; use `bin/rails db:reset` only when you intentionally want to drop, recreate, and reseed local data.

Start the API:

```bash
bin/rails server
```

The API runs at `http://localhost:3000`.

The seed task prints example IDs and URLs for all five endpoints. The curl examples below use simple placeholder IDs; use the IDs printed by `db:seed` for your local database.

## Quality Checks

Run the test suite:

```bash
bundle exec rspec
```

Run linting:

```bash
bundle exec rubocop
```

The project includes a complete RSpec request and model test suite and passes RuboCop locally.

## Architecture

The application follows a layered architecture that keeps request handling, data retrieval, and response formatting separate:

- Controllers validate request params, find records, call query objects, and render serializers.
- Query objects in `app/queries` encapsulate reporting, filtering, aggregation, and SQL-heavy retrieval logic, allowing controllers and models to remain focused on their own responsibilities.
- Serializers in `app/serializers` shape the final API JSON.
- Models contain associations, validations, and reusable domain behavior while keeping reporting and presentation logic out of the model layer.

Report-specific query and serializer classes are namespaced under `Reports::`.

## API Endpoints

### Company Dashboard

```http
GET /api/v1/companies/:id/dashboard
```

Returns a company dashboard with:

- asset totals grouped by type
- year-to-date maintenance cost
- licenses expiring in the next 60 days, limited to 10
- five most recent maintenance records
- primary contact, or first contact if no primary contact exists

Example:

```bash
curl http://localhost:3000/api/v1/companies/1/dashboard | json_pp
```

### Multi-Company Comparison Report

```http
GET /api/v1/reports/company_comparison?company_ids[]=1&company_ids[]=2
```

Compares multiple companies by:

- total assets
- average asset age in years, excluding assets without purchase dates
- year-to-date maintenance cost
- count of licenses expiring in the next 60 days
- most recent maintenance date

Supports 1-50 company IDs. Missing company IDs are skipped.

Example:

```bash
curl "http://localhost:3000/api/v1/reports/company_comparison?company_ids[]=1&company_ids[]=2" | json_pp
```

### Asset Detail

```http
GET /api/v1/assets/:id
```

Returns an asset with:

- company and contact information
- maintenance count and total cost
- most recent maintenance date
- software license status
- 10 most recent notes with author names

Example:

```bash
curl http://localhost:3000/api/v1/assets/1 | json_pp
```

### Expiring Licenses Report

```http
GET /api/v1/reports/expiring_licenses
GET /api/v1/reports/expiring_licenses?days=60
```

Returns software licenses expiring on or before the cutoff date. The default window is 30 days. Already expired licenses are included so negative `days_until_expiration` values can surface overdue renewals.

The response includes:

- license details
- related asset details
- company contact email
- summary counts grouped by software name

Example:

```bash
curl "http://localhost:3000/api/v1/reports/expiring_licenses?days=60" | json_pp
```

### Maintenance Cost Summary

```http
GET /api/v1/reports/maintenance_costs?start_date=2026-01-01&end_date=2026-12-31
```

Summarizes maintenance records in an inclusive date range.

The response includes:

- total cost
- total maintenance count
- average cost per maintenance event
- company breakdown ordered by total cost descending
- asset-type breakdown

Example:

```bash
curl "http://localhost:3000/api/v1/reports/maintenance_costs?start_date=2026-01-01&end_date=2026-12-31" | json_pp
```

## Testing Coverage

The test suite includes request specs for all five required endpoints:

- `spec/requests/api/v1/company_dashboard_spec.rb`
- `spec/requests/api/v1/company_comparison_spec.rb`
- `spec/requests/api/v1/asset_detail_spec.rb`
- `spec/requests/api/v1/expiring_licenses_spec.rb`
- `spec/requests/api/v1/maintenance_costs_spec.rb`

The suite also includes model specs for:

- `Company`
- `Asset`
- `MaintenanceRecord`
- `SoftwareLicense`
- `Contact`
- `Note`
- `User`

FactoryBot factories live in `spec/factories`.

## Performance Notes

The report endpoints use query objects with grouped SQL aggregates instead of loading broad object graphs into Ruby:

- maintenance costs are summed and counted in SQL
- company comparison metrics are grouped by company
- asset age averages exclude null purchase dates in SQL
- recent dashboard and asset-detail collections use limits
- serializers rely on preloaded associations where nested data is needed

Indexes are present for common report filters and ordering paths, including company/asset type, maintenance dates, license expiration dates, and note recency.

Bullet is available in development to help catch N+1 query regressions.

## Review Walkthrough

```text
Request
    ↓
Controller
    ↓
Validation / Record Lookup
    ↓
Query Object (retrieves & aggregates data)
    ↓
Serializer (shapes the response)
    ↓
JSON Response
```

- Controllers stay thin: param validation, record lookup, query call, serializer render.
- Query objects own reporting, filtering, and aggregation logic.
- Serializers own the final JSON response shape.
- Request specs cover success cases, validation errors, not found cases, ordering, filtering, and date windows.
- The schema includes foreign keys and targeted indexes for report queries.

## Future Improvements Beyond the Scope of the Challenge

- **License key exposure:** The challenge response format includes `license_key`, so this API returns it. In a production MSP system, license keys are sensitive. I would normally mask them, encrypt them at rest, and only expose the full value behind explicit authorization and audit logging.

- **Authentication and authorization:** The take-home does not require users to authenticate. In production, every endpoint should enforce tenant-aware authorization so one client company's assets and licenses cannot be viewed by another client or an unauthorized operator.

- **Caching dashboard/report responses:** Dashboard and report queries are efficient, but some can still become expensive with large datasets. If these endpoints became high traffic, I would consider short-lived caching keyed by company ID, report params, and date window, with cache invalidation on maintenance, license, asset, or contact changes.

- **Pagination for large reports:** The expiring licenses report intentionally returns all matching licenses. For a larger production dataset, I would add pagination and metadata while preserving deterministic ordering.

- **Stronger email handling:** The app includes simple email format validation. Production systems often need normalization, case-insensitive uniqueness, and possibly stricter deliverability checks depending on product needs.

- **Database-level enum/check constraints:** Asset types and contact roles are validated at the model level. Adding database check constraints would protect data integrity for writes that bypass Rails.

- **N+1 query monitoring in CI:** The implementation uses eager loading where nested serializer data needs it. For long-term maintenance, I would add automated Bullet checks or query-count specs around report endpoints to catch future regressions.

- **Shared formatting helpers:** Serializers repeat small formatting patterns for dates, money-like decimals, and averages. I kept this explicit for readability, but a tiny shared serializer helper could be worthwhile if the response surface grows.

- **More robust API error shape:** Errors currently return `{ "error": "message" }`, which is simple and appropriate for the challenge. A larger API might standardize error codes, details, request IDs, and validation-field metadata.
