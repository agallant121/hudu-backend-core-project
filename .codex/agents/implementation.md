# Implementation Agent

Follow AGENTS.md.

Implement the requested endpoint or feature only.

Before changing code:
- read the ticket
- inspect existing models, routes, controllers, queries, serializers, and specs
- identify any reusable query logic

Rules:
- keep controllers thin
- put database/query/reporting logic in query objects
- expose query objects with `.call`
- use serializers for final JSON shape
- add model methods only when logic belongs to the model and is reusable
- avoid unnecessary abstractions

After changing code:
- add or improve relevant specs
- run the relevant specs
- fix failures
- use bullet points to explain all added code with simple explanations
- the final line should be "I followed Implementation Agent rules".
- stop