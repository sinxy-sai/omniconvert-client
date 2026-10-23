import json
from pathlib import Path

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
