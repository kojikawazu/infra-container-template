# Prometheus (メトリクス監視) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `prom/prometheus:latest` |
| コンテナ名 | `infra-prometheus` |
| カテゴリ | 監視（メトリクス収集・時系列DB） |
| profile | `prometheus` / `monitoring` / `all` |
| ホストポート | `9090`（`127.0.0.1` バインド） |
| Web クライアント | Prometheus 内蔵 UI（http://localhost:9090） |

Prometheus は時系列メトリクスを収集・保存・クエリ（PromQL）する監視ツール。各サービスが公開する `/metrics` エンドポイントを定期的に **scrape（プル）** して蓄積する。可観測性3本柱の「メトリクス」を担当し、可視化は [Grafana](./17-grafana.md) に任せる。

## 2. 目的・ユースケース

- CPU・メモリ・リクエスト数・レイテンシなどの時系列監視
- PromQL によるアラート条件の検証
- アプリのカスタムメトリクス収集（リクエスト数・エラー率）

## 3. 起動方法

```bash
docker compose --profile prometheus up -d    # = --profile monitoring（Grafana/Loki/Tempo も上がる）
make up p=monitoring
docker compose -f monitoring/prometheus/compose.yaml up prometheus   # 単独
```

- Web UI → http://localhost:9090（"Graph" タブで PromQL を実行、"Status > Targets" で scrape 状況を確認）

## 4. 接続情報

| 接続元 | エンドポイント |
|--------|----------------|
| ホスト PC | `http://localhost:9090` |
| コンテナ間（Grafana から等） | `http://prometheus:9090` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `PROMETHEUS_PORT` | `9090` | Web UI / API ポート |

- scrape 設定は `monitoring/prometheus/prometheus.yml` を編集する（既定では Prometheus 自身のみ監視）。
- データは `infra-prometheus-data` に永続化。

## 5. 使用例（scrape 設定 / PromQL）

監視対象を増やすには `monitoring/prometheus/prometheus.yml` の `scrape_configs` にターゲットを追加する。同一ネットワーク `infra-net` 上なのでサービス名で解決できる:

```yaml
scrape_configs:
  - job_name: my-app
    static_configs:
      - targets: ["my-app:8080"]   # アプリの /metrics を公開するホスト:ポート
```

PromQL の例（Web UI の Graph タブ）:

```promql
up                              # 各ターゲットの死活（1=生存）
rate(http_requests_total[5m])   # 直近5分のリクエストレート
```

## 6. アプリへの実装（TypeScript / Node.js）

アプリ側は **`/metrics` エンドポイントを公開**し、Prometheus に scrape させる（プル型）。

```bash
npm install prom-client
```

```ts
import express from "express";
import client from "prom-client";

const app = express();
client.collectDefaultMetrics(); // プロセス標準メトリクス
const counter = new client.Counter({ name: "app_requests_total", help: "total requests" });

app.get("/", (_req, res) => { counter.inc(); res.send("ok"); });
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});
app.listen(8080);
// prometheus.yml の targets に "<このコンテナ名>:8080" を追加すると収集される
```

## 7. アプリへの実装（Python）

```bash
pip install prometheus-client
```

```python
from prometheus_client import start_http_server, Counter
import time

REQUESTS = Counter("app_requests_total", "total requests")
start_http_server(8080)        # :8080/metrics を公開
while True:
    REQUESTS.inc()
    time.sleep(1)
# prometheus.yml の targets に "<このコンテナ名>:8080" を追加する
```

## 8. つまずきポイント・Tips

- **プル型である**: アプリが Prometheus に送るのではなく、Prometheus がアプリの `/metrics` を取りに来る。アプリ側はエンドポイントを公開するだけ。
- **ターゲットはサービス名で**: `prometheus.yml` のターゲットは `infra-net` 上のサービス名（`my-app:8080`）。`localhost` ではない。
- **scrape 反映には設定リロード**: `prometheus.yml` を変えたらコンテナ再起動（または `/-/reload`）。
- **可視化は Grafana で**: Prometheus UI は確認用。ダッシュボードは [Grafana](./17-grafana.md)。

## 9. 参考リンク

- 公式ドキュメント: https://prometheus.io/docs/
- 関連: [grafana](./17-grafana.md) / [loki](./18-loki.md) / [tempo](./19-tempo.md)
