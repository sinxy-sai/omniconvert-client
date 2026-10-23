"""Deterministic, in-memory OCR provider used by client integration tests."""

from dataclasses import dataclass


@dataclass(frozen=True)
class MockResponse:
    request_id: str
    latex: str
    model_version: str
    warnings: list[str]


class MockProvider:
    protocol_version = 'ocr-provider-v1'

    def __init__(self) -> None:
        self._requests: dict[str, MockResponse] = {}

    def capabilities(self) -> dict:
        return {
            'protocolVersion': self.protocol_version,
            'modes': ['formula'],
            'maxBytes': 10 * 1024 * 1024,
            'maxTimeoutSeconds': 30,
        }

    def recognize(self, image: bytes, mode: str, idempotency_key: str, timeout_seconds: int = 20) -> MockResponse:
        if not image:
            raise ValueError('image is required')
        if mode != 'formula':
            raise ValueError('unsupported mode')
        if not 1 <= timeout_seconds <= 30:
            raise TimeoutError('timeout exceeds provider limit')
        if len(image) > self.capabilities()['maxBytes']:
            raise ValueError('image exceeds maxBytes')
        if idempotency_key in self._requests:
            return self._requests[idempotency_key]
        response = MockResponse(
            request_id=f'mock-{len(self._requests) + 1:04d}',
            latex=r'\frac{a}{b}',
            model_version='mock-1',
            warnings=[],
        )
        self._requests[idempotency_key] = response
        return response
