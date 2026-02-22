# Prompt Versioning

## Versioning convention

- `v1.x`: baseline crawl-and-store prompts
- `v2.x`: refined prompts + second-stage filtering criteria
- `v3.x`: agent-based retrieval + classification prompts

## Change principles

- Every prompt change must document:
  - target version
  - expected impact (precision, recall, or both)
  - linked evaluation report
- Prompt schema changes must remain backward-compatible when possible.
- Never store secrets or private infrastructure details in prompt files.

## Traceability fields

Track these fields in Candidate snapshots:
- `model_version`
- `prompt_version`
- `executed_at`
- `confidence`
