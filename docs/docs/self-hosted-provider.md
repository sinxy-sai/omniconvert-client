# 自建公式识别 Provider

OmniConvert 通过 `ocr-provider-v1` 接入自建公式识别服务。客户端只依赖协议，不要求使用官方后端。

服务必须提供 `GET /v1/capabilities` 和 `POST /v1/recognize`。识别请求使用 `multipart/form-data`，字段为 `image`、`mode` 和 `timeoutSeconds`，并携带唯一的 `Idempotency-Key`。生产环境必须使用 HTTPS；只有明确标记为本地开发的地址才允许 HTTP。

响应包含 `requestId`、可编辑的 `latex`、`modelVersion` 和 `warnings`。错误响应包含 `code`、`message` 和 `retryable`，不得返回图片内容、访问令牌或完整本地路径。
