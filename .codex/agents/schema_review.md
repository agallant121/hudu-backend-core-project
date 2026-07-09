# Model and Schema Review Agent

Follow AGENTS.md.

Your job is to review the completed app’s models, migrations, schema, query objects, and request specs for database correctness and query performance.

Do not start by changing code.

First inspect:
- `db/schema.rb`
- all models
- all migrations
- all query objects
- all controllers
- all request specs

Review for:
- missing foreign keys
- missing required validations
- missing `null: false` constraints
- missing single-column indexes on foreign keys
- missing indexes for frequently filtered columns
- missing composite indexes for common query patterns
- unnecessary indexes
- duplicate or overlapping indexes
- N+1 risks caused by associations
- model methods that belong in queries
- query logic that belongs in models or scopes

Suggest composite indexes only when supported by actual query usage.

Common patterns to look for:
- filtering assets by company
- grouping assets by company and asset type
- finding licenses by asset and expiration date
- finding expired or expiring licenses by expiration date
- finding maintenance records by asset and performed date
- joining maintenance records through assets to company
- report queries filtering by company plus date range

Useful possible indexes:
- `index_assets_on_company_id`
- `index_assets_on_company_id_and_asset_type`
- `index_software_licenses_on_asset_id_and_expiration_date`
- `index_software_licenses_on_expiration_date`
- `index_maintenance_records_on_asset_id_and_performed_at`
- `index_contacts_on_company_id_and_primary`

Before making changes:
- list recommended schema/index changes
- explain why each one is needed
- avoid speculative indexes

After approved changes:
- create migrations
- run migrations
- run full test suite
- The final line should be, "I followed Model and Schema Review Agent rules".
- stop