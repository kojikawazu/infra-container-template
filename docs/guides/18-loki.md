# Loki (ログ集約) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `grafana/loki:3.1.1` |
| コンテナ名 | `infra-loki` |
| カテゴリ | 監視（ログ集約） |
| profile | `loki` / `monitoring` / `all` |
| ホストポート | `3100`（`127.0.0.1` バインド） |
| Web クライアント | なし（[Grafana](./17-grafana.md) から参照） |

Loki は「Prometheus のログ版」と呼ばれる軽量なログ集約システム。ログ全文をインデックスせず**ラベルだけをインデックス**するため低コスト。可観測性3本柱の「ログ」を担当し、閲覧は [Grafana](./17-grafana.md) の Explore / LogQL で行う。

## 2. 目的・ユースケース

- 複数コンテナ/サービスのログを一元集約
- LogQL によるログ検索・フィルタ・集計
- メトリクス（Prometheus）・トレース（Tempo）とログを Grafana で相関分析

## 3. 起動方法

```bash
docker compose --profile loki up -d          # = --profile monitoring（Grafana 等も上がる）
make up p=monitoring
docker compose -f monitoring/loki/compose.yaml up loki   # 単独
```

- 単独では UI を持たない。**Grafana の Explore でデータソース `Loki` を選ぶ**と閲覧できる（自動登録済み）。

## 4. 接続情報

| 接続元 | エンドポイント |
|--------|----------------|
| ホスト PC | `http://localhost:3100` |
| コンテナ間（Grafana/送信側から） | `http://loki:3100` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `LOKI_PORT` | `3100` | HTTP API（push / query）ポート |

- 単一ノード構成では同梱の `local-config.yaml` で十分動く（追加設定不要）。
- データは `infra-loki-data` に永続化。

## 5. 使用例（CLI / push & query API）

```bash
# 準備確認
curl http://localhost:3100/ready          # "ready" が返れば受付可能

# ログを1件 push（タイムスタンプはナノ秒文字列）
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H 'Content-Type: application/json' \
  -d '{"streams":[{"stream":{"app":"demo"},"values":[["'$(date +%s%N)'","hello loki"]]}]}'

# クエリ（LogQL）
curl -G http://localhost:3100/loki/api/v1/query_range \
  --data-urlencode 'query={app="demo"}'
```

## 6. アプリへの実装（TypeScript / Node.js）

アプリログを Loki に送るには専用トランスポートを使う（push 型）。

```bash
npm install winston winston-loki
```

```ts
import winston from "winston";
import LokiTransport from "winston-loki";

const logger = winston.createLogger({
  transports: [
    new LokiTransport({
      host: process.env.LOKI_HOST ?? "http://localhost:3100", // コンテナ間は http://loki:3100
      labels: { app: "demo" },
      json: true,
    }),
  ],
});

logger.info("hello loki"); // Grafana の Explore で {app="demo"} で検索できる
```

## 7. アプリへの実装（Python）

```bash
pip install python-logging-loki
```

```python
import logging
from logging_loki import LokiHandler

handler = LokiHandler(
    url="http://localhost:3100/loki/api/v1/push",  # コンテナ間は http://loki:3100
    tags={"app": "demo"},
    version="1",
)
logger = logging.getLogger("demo")
logger.addHandler(handler)
logger.error("hello loki")  # Grafana の Explore で {app="demo"}
```

## 8. つまずきポイント・Tips

- **全文インデックスではない**: Loki はラベル（`{app="demo"}`）で絞ってから本文を grep する設計。ラベル設計が検索性を左右する。ラベルの種類を増やしすぎない。
- **閲覧は Grafana**: Loki 単体に UI はない。`--profile monitoring` で Grafana ごと起動する。
- **`localhost` と `loki` の取り違え**: ホストのアプリは `localhost:3100`、コンテナ内は `loki:3100`。
- **コンテナログを丸ごと集めたい場合**: Promtail / Grafana Alloy / Docker の loki ログドライバ等を別途使う（本テンプレは Loki 本体のみ）。

## 9. 参考リンク

- 公式ドキュメント: https://grafana.com/docs/loki/latest/
- 関連: [grafana](./17-grafana.md) / [prometheus](./16-prometheus.md) / [tempo](./19-tempo.md)
