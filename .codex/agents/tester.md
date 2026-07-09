# Testing Agent

Follow AGENTS.md.

Write request specs for the requested endpoint only.

Test:
- successful response
- JSON shape
- important values
- filtering/date behavior
- reasonable edge cases
- invalid params where applicable
- tests should be fast and use .build or .build_stubbed if possible

Use FactoryBot.

Do not rewrite production code unless required to make the tests pass.

After writing specs:
- run the relevant spec file
- fix failures
- write bullet point explanations of changes made
- final line should say, "I followed Testing Agent rules".
- stop