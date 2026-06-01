# BigQuery emulator 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `ghcr.io/goccy/bigquery-emulator:latest` |
| コンテナ名 | `infra-bigquery` |
| カテゴリ | エミュレータ（Google BigQuery のローカル代替） |
| profile | `bigquery` / `emulator` / `all` |
| ホストポート | REST `9050` / gRPC `9060`（`127.0.0.1` バインド） |
| Web クライアント | なし（クライアントライブラリで操作） |

BigQuery emulator（goccy/bigquery-emulator）は Google BigQuery の API をローカルで模倣する OSS。実 GCP に接続せず、SQL クエリ・データセット/テーブル操作を検証できる。クライアントライブラリのエンドポイントを差し替えて使う。

## 2. 目的・ユースケース

- BigQuery を使うアプリ/バッチのローカル開発・CI（GCP 課金なし）
- BigQuery SQL の学習
- データパイプラインのテスト

## 3. 起動方法

```bash
docker compose --profile bigquery up -d      # = --profile emulator（LocalStack も上がる）
make up p=emulator
docker compose -f emulators/bigquery/compose.yaml up bigquery   # 単独
```

> このエミュレータには Web UI はない。クライアントライブラリ（下記）で操作する。

## 4. 接続情報

| 接続元 | REST エンドポイント |
|--------|---------------------|
| ホスト PC | `http://localhost:9050` |
| コンテナ間 | `http://bigquery:9050` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `BIGQUERY_PROJECT` | `local-project` | プロジェクトID（実 GCP 不要） |
| `BIGQUERY_REST_PORT` | `9050` | REST ポート |
| `BIGQUERY_GRPC_PORT` | `9060` | gRPC ポート |

- ⚠ クライアントライブラリは **`apiEndpoint`（または `api_endpoint`）の差し替えが必須**。認証はダミーで通る。
- ⚠ コミュニティ製エミュレータのため実 BigQuery と完全互換ではない（学習・CI 用途）。

## 5. 使用例（CLI / curl）

```bash
# データセット一覧（REST API を直接叩く例）
curl http://localhost:9050/bigquery/v2/projects/local-project/datasets
```

> 実務ではクライアントライブラリ経由が一般的（下記）。

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install @google-cloud/bigquery
```

```ts
import { BigQuery } from "@google-cloud/bigquery";

const bq = new BigQuery({
  projectId: "local-project",
  apiEndpoint: process.env.BQ_ENDPOINT ?? "http://localhost:9050", // コンテナ間は http://bigquery:9050
});

await bq.createDataset("demo").catch(() => {});
const [job] = await bq.createQueryJob({ query: "SELECT 1 AS n" });
const [rows] = await job.getQueryResults();
console.log(rows); // [{ n: 1 }]
```

## 7. アプリへの実装（Python）

```bash
pip install google-cloud-bigquery
```

```python
from google.cloud import bigquery
from google.api_core.client_options import ClientOptions
from google.auth.credentials import AnonymousCredentials

client = bigquery.Client(
    project="local-project",
    client_options=ClientOptions(api_endpoint="http://localhost:9050"),  # コンテナ間は http://bigquery:9050
    credentials=AnonymousCredentials(),
)
rows = client.query("SELECT 1 AS n").result()
print([dict(r) for r in rows])
```

## 8. つまずきポイント・Tips

- **`apiEndpoint` の差し替え必須**: 指定しないと実 BigQuery（GCP）に接続しようとして認証エラーになる。
- **認証はダミー**: ローカルなので `AnonymousCredentials`（Python）等で OK。
- **`localhost` と `bigquery` の取り違え**: ホストのアプリは `http://localhost:9050`、コンテナ内は `http://bigquery:9050`。
- **互換性の限界**: 一部の関数・機能は未実装。エラーが出たら実 BigQuery 固有機能を疑う。

## 9. 参考リンク

- bigquery-emulator: https://github.com/goccy/bigquery-emulator
- BigQuery 公式: https://cloud.google.com/bigquery/docs
