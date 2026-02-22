# Evaluation - Pipeline Quality Monitoring

This module measures classification performance against a fixed reference set.
It is not a pipeline layer. It observes and reports, but does not transform data.

## Reference set

- 228 candidate URLs
- 73 confirmed food sharing initiatives
- Fixed across all versions (not updated between runs)

## Metrics tracked

- Accuracy, Precision, Recall, F1 per pipeline version
- False positive category distribution

## Results

| Version | Accuracy | Key change |
|---------|----------|------------|
| v1.0.0 | 32.0% | Baseline |
| v2.0.0 | 68.9% | Prompt refinement + 2nd stage filter |
| v3.0.0 | 74.5% | Agent-based classification |

Detailed version-level reports are in `reports/`.
