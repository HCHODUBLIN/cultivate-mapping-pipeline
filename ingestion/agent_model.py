"""Agent-based classification facade (v3.x).

The real agent implementation can include retrieval tools and multi-step reasoning.
This public repository keeps only the integration contract.
"""

from __future__ import annotations

from dataclasses import dataclass

try:
    from .llm_classifier import ClassificationSnapshot, LLMClassifier
except ImportError:  # pragma: no cover - fallback for direct execution contexts
    from llm_classifier import ClassificationSnapshot, LLMClassifier


@dataclass(frozen=True)
class AgentConfig:
    model_version: str = "v3.0.0"
    prompt_version: str = "agent-default"


class AgentClassifier(LLMClassifier):
    """Thin extension point for agent-style ingestion."""

    def __init__(self, config: AgentConfig) -> None:
        super().__init__(model_version=config.model_version, prompt_version=config.prompt_version)

    def classify(self, source_url: str, context: dict | None = None) -> ClassificationSnapshot:
        # Delegate to shared contract; replace with real agent orchestration in private runtime.
        return super().classify(source_url, context=context)
