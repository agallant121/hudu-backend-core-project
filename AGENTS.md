# Rails API Development Guidelines

Read the ticket instructions carefully before making changes.

Implement only what the ticket asks for.

Prefer the simplest solution that is clean, readable, and production-ready.

## Architecture

- Keep controllers thin.
- Keep business logic out of controllers.
- Keep models focused on model behavior.
- Favor composition over duplication.
- Do not overengineer.

## Query Objects

If data is being queried, filtered, grouped, aggregated, compared, or prepared from the database, create or reuse a query object.

Query objects should:

- live in `app/queries`
- use `(...).call`
- return reusable Ruby objects or hashes
- not return final API JSON
- avoid presentation logic
- If a query object becomes responsible for multiple concerns, extract reusable query objects instead of duplicating SQL.

Reuse query objects when multiple endpoints require similar data.

## Models

Model methods should only contain logic that naturally belongs to that model and can be reused.

Examples:

- `company.primary_contact`
- `license.expired?`
- `license.expiring_within?(days)`

Do not place reporting logic in models.

## Serializers

Serializers own the API response.

They should:

- live in `app/serializers`
- use `.new(data).as_json`
- shape the final JSON response
- control nesting and field names
- format dates and values when appropriate

Query objects gather data.

Serializers present data.

## Controllers

Controllers should:

- validate params
- find records
- call a query object
- render a serializer
- return appropriate HTTP status codes

Controllers should not perform business logic or complex queries.

## Testing

Write request specs for every endpoint.

Use FactoryBot.

Test:

- success cases
- invalid parameters
- not found cases
- filtering
- JSON response structure
- should use build over create when possible
- should use build_stubbed when possible
- tests should be accurate and fast while maintaining integrity

## Code Quality

- Prefer readability over cleverness.
- Prevent N+1 queries.
- Remove duplicate logic.
- Keep methods short.
- Follow Rails conventions.
- Leave the codebase cleaner than you found it.

## Simplicity

When there are multiple valid implementations:

- Prefer the simplest production-ready solution.
- Do not introduce abstractions until there is a demonstrated need.
- Reuse existing query objects before creating new ones.
- Avoid creating service objects unless business logic extends beyond querying or serialization.
- Keep the code easy for another Rails developer to understand and maintain.