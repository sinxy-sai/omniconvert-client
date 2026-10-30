#!/usr/bin/env python3
"""Generate every consumer of ``tool/registry.json`` from the single source of truth.

Run from the ``OmniConvert-client`` repository root::

    python tool/generate_registry.py            # write all generated files
    python tool/generate_registry.py --check     # verify generated files are current

Outputs (all committed so the repos build standalone):

* ``lib/core/tools/tool_registry.g.dart``                  Flutter client
* ``../OmniConvert-site/src/lib/capabilities.generated.json``  Website build data
* ``../OmniConvert-backend/app/conversion/capabilities_generated.py``  API capabilities
* ``docs/capabilities.md``                                 Human documentation

Only the standard library is used, so CI does not need extra dependencies.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

CLIENT_ROOT = Path(__file__).resolve().parent.parent
WORKSPACE_ROOT = CLIENT_ROOT.parent
REGISTRY_PATH = CLIENT_ROOT / "tool" / "registry.json"

DART_PATH = CLIENT_ROOT / "lib" / "core" / "tools" / "tool_registry.g.dart"
SITE_PATH = WORKSPACE_ROOT / "OmniConvert-site" / "src" / "lib" / "capabilities.generated.json"
BACKEND_PATH = (
    WORKSPACE_ROOT / "OmniConvert-backend" / "app" / "conversion" / "capabilities_generated.py"
)
DOCS_PATH = CLIENT_ROOT / "docs" / "capabilities.md"

BANNER = "GENERATED FROM OmniConvert-client/tool/registry.json — DO NOT EDIT BY HAND."


def load_registry() -> dict[str, Any]:
    with REGISTRY_PATH.open(encoding="utf-8") as handle:
        registry = json.load(handle)
    validate(registry)
    return registry


def validate(registry: dict[str, Any]) -> None:
    """Fail loudly on a registry that would generate broken clients."""
    tools = registry.get("tools")
    if not isinstance(tools, list) or not tools:
        raise SystemExit("registry.json: `tools` must be a non-empty list")
    seen: set[str] = set()
    categories = {category["id"] for category in registry.get("categories", [])}
    for tool in tools:
        tool_id = tool.get("id")
        if not tool_id:
            raise SystemExit("registry.json: every tool needs an `id`")
        if tool_id in seen:
            raise SystemExit(f"registry.json: duplicate tool id {tool_id!r}")
        seen.add(tool_id)
        for key in ("name", "summary", "inputExtensions", "outputExtension", "engine", "category"):
            if key not in tool:
                raise SystemExit(f"registry.json: tool {tool_id!r} is missing {key!r}")
        if tool["engine"] not in ("local", "server"):
            raise SystemExit(f"registry.json: tool {tool_id!r} has unknown engine {tool['engine']!r}")
        if tool["category"] not in categories:
            raise SystemExit(f"registry.json: tool {tool_id!r} uses unknown category {tool['category']!r}")
        if not tool["inputExtensions"]:
            raise SystemExit(f"registry.json: tool {tool_id!r} needs at least one input extension")
        for extension in tool["inputExtensions"]:
            if extension != extension.lower() or extension.startswith("."):
                raise SystemExit(
                    f"registry.json: tool {tool_id!r} extension {extension!r} must be lowercase and dot-free"
                )
        for option in tool.get("options", []):
            if option.get("type") not in ("integer", "enum", "boolean", "string"):
                raise SystemExit(
                    f"registry.json: tool {tool_id!r} option {option.get('id')!r} has unknown type"
                )


def dart_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    return f"'{escaped}'"


def dart_map(translations: dict[str, str]) -> str:
    pairs = ", ".join(f"{dart_string(key)}: {dart_string(value)}" for key, value in translations.items())
    return f"<String, String>{{{pairs}}}"


def render_dart(registry: dict[str, Any]) -> str:
    lines = [
        "// " + BANNER,
        "// Regenerate with: python tool/generate_registry.py",
        "",
        "/// One tunable option of a tool.",
        "class ToolOptionDefinition {",
        "  const ToolOptionDefinition({",
        "    required this.id,",
        "    required this.type,",
        "    required this.label,",
        "    this.min,",
        "    this.max,",
        "    this.defaultValue,",
        "    this.values = const <String>[],",
        "  });",
        "",
        "  final String id;",
        "  final String type;",
        "  final Map<String, String> label;",
        "  final int? min;",
        "  final int? max;",
        "  final String? defaultValue;",
        "  final List<String> values;",
        "}",
        "",
        "/// A tool as declared by the single-source registry.",
        "class ToolDefinition {",
        "  const ToolDefinition({",
        "    required this.id,",
        "    required this.name,",
        "    required this.summary,",
        "    required this.category,",
        "    required this.engine,",
        "    required this.inputExtensions,",
        "    required this.outputExtension,",
        "    this.options = const <ToolOptionDefinition>[],",
        "  });",
        "",
        "  final String id;",
        "  final Map<String, String> name;",
        "  final Map<String, String> summary;",
        "  final String category;",
        "  final String engine;",
        "  final List<String> inputExtensions;",
        "",
        "  /// `same` means the output keeps the input format (compression).",
        "  final String outputExtension;",
        "  final List<ToolOptionDefinition> options;",
        "",
        "  bool get isLocal => engine == 'local';",
        "",
        "  bool get keepsFormat => outputExtension == 'same';",
        "",
        "  /// Output extension for a concrete input file.",
        "  String resolveOutputExtension(String inputExtension) {",
        "    final normalised = inputExtension.toLowerCase().replaceFirst('.', '');",
        "    if (!keepsFormat) return outputExtension;",
        "    return normalised == 'jpeg' ? 'jpg' : normalised;",
        "  }",
        "",
        "  bool accepts(String path) {",
        "    final name = path.split(RegExp(r'[\\\\/]')).last;",
        "    final dot = name.lastIndexOf('.');",
        "    if (dot < 0) return false;",
        "    return inputExtensions.contains(name.substring(dot + 1).toLowerCase());",
        "  }",
        "",
        "  String? optionDefault(String optionId) {",
        "    for (final option in options) {",
        "      if (option.id == optionId) return option.defaultValue;",
        "    }",
        "    return null;",
        "  }",
        "}",
        "",
        "const int kMaxInputBytes = %d;" % registry["limits"]["maxInputBytes"],
        "const int kMaxImagePixels = %d;" % registry["limits"]["maxImagePixels"],
        "",
        "const List<ToolDefinition> kToolDefinitions = <ToolDefinition>[",
    ]
    for tool in registry["tools"]:
        lines.append("  ToolDefinition(")
        lines.append(f"    id: {dart_string(tool['id'])},")
        lines.append(f"    name: {dart_map(tool['name'])},")
        lines.append(f"    summary: {dart_map(tool['summary'])},")
        lines.append(f"    category: {dart_string(tool['category'])},")
        lines.append(f"    engine: {dart_string(tool['engine'])},")
        extensions = ", ".join(dart_string(extension) for extension in tool["inputExtensions"])
        # No `const` here: the whole kToolDefinitions list is already a const
        # context, so repeating it trips the `unnecessary_const` lint.
        lines.append(f"    inputExtensions: <String>[{extensions}],")
        lines.append(f"    outputExtension: {dart_string(tool['outputExtension'])},")
        options = tool.get("options", [])
        if options:
            lines.append("    options: <ToolOptionDefinition>[")
            for option in options:
                parts = [
                    f"id: {dart_string(option['id'])}",
                    f"type: {dart_string(option['type'])}",
                    f"label: {dart_map(option['label'])}",
                ]
                if option.get("min") is not None:
                    parts.append(f"min: {option['min']}")
                if option.get("max") is not None:
                    parts.append(f"max: {option['max']}")
                if option.get("default") is not None:
                    parts.append(f"defaultValue: {dart_string(str(option['default']))}")
                if option.get("values"):
                    values = ", ".join(dart_string(value) for value in option["values"])
                    parts.append(f"values: <String>[{values}]")
                lines.append(f"      ToolOptionDefinition({', '.join(parts)}),")
            lines.append("    ],")
        lines.append("  ),")
    lines.append("];")
    lines.append("")
    lines.append("/// Look up a tool definition, or `null` for an unknown id.")
    lines.append("ToolDefinition? toolDefinitionFor(String id) {")
    lines.append("  for (final definition in kToolDefinitions) {")
    lines.append("    if (definition.id == id) return definition;")
    lines.append("  }")
    lines.append("  return null;")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def render_site(registry: dict[str, Any]) -> str:
    payload = {
        "generatedFrom": "OmniConvert-client/tool/registry.json",
        "registryVersion": registry["registryVersion"],
        "maxInputBytes": registry["limits"]["maxInputBytes"],
        "categories": registry["categories"],
        "tools": registry["tools"],
        "serverFormats": sorted(
            {
                extension
                for tool in registry["tools"]
                if tool["engine"] == "server"
                for extension in tool["inputExtensions"]
            }
        ),
    }
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def render_backend(registry: dict[str, Any]) -> str:
    server_tools = [tool for tool in registry["tools"] if tool["engine"] == "server"]
    server_formats = sorted({extension for tool in server_tools for extension in tool["inputExtensions"]})
    return (
        f'"""{"GENERATED FROM OmniConvert-client/tool/registry.json - DO NOT EDIT BY HAND."}"""\n'
        "\n"
        "from __future__ import annotations\n"
        "\n"
        f"REGISTRY_VERSION = {registry['registryVersion']}\n"
        f"MAX_INPUT_BYTES = {registry['limits']['maxInputBytes']}\n"
        f"SERVER_FORMATS: tuple[str, ...] = {tuple(server_formats)!r}\n"
        f"SERVER_TOOLS: tuple[str, ...] = {tuple(tool['id'] for tool in server_tools)!r}\n"
        "\n"
        "\n"
        "def capabilities() -> dict[str, object]:\n"
        '    """Shape returned by GET /v1/conversions/capabilities."""\n'
        "    return {\n"
        '        "formats": list(SERVER_FORMATS),\n'
        '        "output": "pdf",\n'
        '        "maxBytes": MAX_INPUT_BYTES,\n'
        '        "registryVersion": REGISTRY_VERSION,\n'
        f'        "tools": list(SERVER_TOOLS),\n'
        "    }\n"
    )


def render_docs(registry: dict[str, Any]) -> str:
    lines = [
        "# 支持的能力（自动生成）",
        "",
        "> " + BANNER,
        "> 重新生成：`python tool/generate_registry.py`",
        "",
        f"单文件上限：{registry['limits']['maxInputBytes'] // (1024 * 1024)} MiB。",
        "",
        "| 工具 ID | 名称 | 输入 | 输出 | 处理位置 |",
        "|---|---|---|---|---|",
    ]
    for tool in registry["tools"]:
        inputs = " / ".join(extension.upper() for extension in tool["inputExtensions"])
        output = "同输入格式" if tool["outputExtension"] == "same" else tool["outputExtension"].upper()
        location = "本机" if tool["engine"] == "local" else "服务器"
        lines.append(f"| `{tool['id']}` | {tool['name']['zh']} | {inputs} | {output} | {location} |")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify generated files are up to date")
    arguments = parser.parse_args()

    registry = load_registry()
    outputs = {
        DART_PATH: render_dart(registry),
        SITE_PATH: render_site(registry),
        BACKEND_PATH: render_backend(registry),
        DOCS_PATH: render_docs(registry),
    }

    stale: list[str] = []
    for path, content in outputs.items():
        if arguments.check:
            existing = path.read_text(encoding="utf-8") if path.exists() else ""
            if existing != content:
                stale.append(str(path))
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
        print(f"wrote {path.relative_to(WORKSPACE_ROOT)}")

    if arguments.check:
        if stale:
            print("stale generated files (run `python tool/generate_registry.py`):", file=sys.stderr)
            for path in stale:
                print(f"  {path}", file=sys.stderr)
            return 1
        print("registry outputs are up to date")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())