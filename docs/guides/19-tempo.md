# Tempo (分散トレース) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `grafana/tempo:2.6.1` |
| コンテナ名 | `infra-tempo` |
| カテゴリ | 監視（分散トレース） |
| profile | `tempo` / `monitoring` / `all` |
| ホストポート | クエリ `3200` / OTLP gRPC `4317` / OTLP HTTP `4318`（`127.0.0.1` バインド） |
| Web クライアント | なし（[Grafana](./17-grafana.md) から参照） |

Tempo は分散トレースのバックエンド。マイクロサービス間をまたぐ1リクエストの流れ（スパンの連なり）を保存し、ボトルネックや失敗箇所を特定する。アプリは **OpenTelemetry (OTLP)** でトレースを送信し、閲覧は [Grafana](./17-grafana.md) で行う。可観測性3本柱の「トレース」を担当。

## 2. 目的・ユースケース

- マイクロサービス間のレイテンシ/ボトルネック分析
- 1リクエストがどのサービスを通ったかの可視化
- メトリクス・ログとトレースの相関（Grafana）

## 3. 起動方法

```bash
docker compose --profile tempo up -d         # = --profile monitoring（Grafana 等も上がる）
make up p=monitoring
docker compose -f monitoring/tempo/compose.yaml up tempo   # 単独
```

- 単独では UI を持たない。**Grafana の Explore でデータソース `Tempo`** を選ぶとトレースを検索・表示できる（自動登録済み）。

## 4. 接続情報

| 用途 | 接続元 | エンドポイント |
|------|--------|----------------|
| トレース送信（OTLP gRPC） | アプリ（コンテナ間） | `tempo:4317` |
| トレース送信（OTLP HTTP） | アプリ（コンテナ間） | `http://tempo:4318` |
| トレース送信（ホストから） | ホスト PC | `localhost:4317` / `http://localhost:4318` |
| クエリ/UI 連携 | Grafana | `http://tempo:3200` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `TEMPO_PORT` | `3200` | クエリ/UI 連携ポート |
| `TEMPO_OTLP_GRPC_PORT` | `4317` | OTLP gRPC 受信 |
| `TEMPO_OTLP_HTTP_PORT` | `4318` | OTLP HTTP 受信 |

- 設定は `monitoring/tempo/tempo.yaml`（単一ノード・ローカルストレージ・保持24h）。データは `infra-tempo-data` に永続化。

## 5. 使用例（疎通確認）

```bash
curl http://localhost:3200/ready          # "ready" が返れば受付可能
```

> トレースの送信はアプリ側の OpenTelemetry SDK で行う（下記）。送ったトレースは Grafana の Explore（Tempo）で TraceID 検索・サービスグラフ表示できる。

## 6. アプリへの実装（TypeScript / Node.js）

OpenTelemetry SDK で OTLP エクスポータを設定し、`tempo:4317`（gRPC）へ送る。

```bash
npm install @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-grpc @opentelemetry/auto-instrumentations-node
```

```ts
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-grpc";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTLP_ENDPOINT ?? "http://localhost:4317", // コンテナ間は http://tempo:4317
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start(); // 以降、HTTP/DB 呼び出しが自動でトレースされ Tempo に送られる
```

## 7. アプリへの実装（Python）

```bash
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc
```

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
# コンテナ間は endpoint="http://tempo:4317"
provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True))
)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("demo")
with tracer.start_as_current_span("handle-request"):
    print("doing work")  # このスパンが Tempo に送られる
```

## 8. つまずきポイント・Tips

- **送信先ポートを間違えない**: トレース送信は OTLP の **4317(gRPC) / 4318(HTTP)**。クエリ用の 3200 ではない。
- **`localhost` と `tempo` の取り違え**: ホストのアプリは `localhost:4317`、コンテナ内は `tempo:4317`。
- **閲覧は Grafana**: Tempo 単体に UI はない。`--profile monitoring` で Grafana ごと起動。TraceID で検索する。
- **保持は24時間**: 検証用に短く設定（`tempo.yaml` の `block_retention`）。長期保持は設定変更が必要。

## 9. 参考リンク

- 公式ドキュメント: https://grafana.com/docs/tempo/latest/
- OpenTelemetry: https://opentelemetry.io/docs/
- 関連: [grafana](./17-grafana.md) / [prometheus](./16-prometheus.md) / [loki](./18-loki.md)
