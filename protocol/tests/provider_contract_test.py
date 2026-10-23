import json
from pathlib import Path

from protocol.mock_provider import MockProvider

ROOT = Path(__file__).parents[1]


def test_examples_match_required_response_fields():
    response = json.loads((ROOT / 'examples' / 'recognize-response.json').read_text())
    assert set(('requestId', 'latex', 'modelVersion', 'warnings')) <= response.keys()
    assert response['latex']
    assert isinstance(response['warnings'], list)


def test_openapi_declares_required_operations_and_errors():
    document = (ROOT / 'ocr-provider-v1.openapi.yaml').read_text()
    for marker in ('/v1/capabilities:', '/v1/recognize:', 'Idempotency-Key', "'408'", "'409'", "'503'"):
        assert marker in document


def test_mock_provider_is_deterministic_and_idempotent():
    provider = MockProvider()
    first = provider.recognize(b'image', 'formula', 'request-key-0001')
    second = provider.recognize(b'image-changed', 'formula', 'request-key-0001')
    assert first == second
    assert first.latex == r'\frac{a}{b}'
    assert provider.capabilities()['protocolVersion'] == 'ocr-provider-v1'


def test_mock_provider_rejects_invalid_requests():
    provider = MockProvider()
    for args in ((b'', 'formula', 'request-key-0002'), (b'image', 'text', 'request-key-0003')):
        try:
            provider.recognize(*args)
        except ValueError:
            pass
        else:
            raise AssertionError('invalid request was accepted')
