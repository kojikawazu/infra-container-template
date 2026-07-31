# 学習ガイド一覧（コンテナ別）

各コンテナの「概要 → 目的 → 起動 → 接続 → 使用例 → アプリ実装（CLI / TypeScript / Python）→ つまずき」を 1 サービス 1 ファイルでまとめた学習用ドキュメント。テンプレに収録された 19 サービスを対象とする。

## はじめに（全ガイド共通の原則）

- **2系統の接続先**:
  - ホスト PC（自分の Mac/PC）で動かすアプリ/CLI からは **`localhost:<ポート>`**
  - 同じ Docker ネットワーク `infra-net` 上のコンテナ（クライアントや別アプリ）からは **サービス名**（例: `postgres`, `kafka:19092`）
  - ⚠ コンテナ内から `localhost` を指定すると「自分自身」を指して接続できない。最頻出のミス。
- **起動は profile 選択制**: profile 未指定では何も起動しない。`docker compose --profile <名前> up -d`（または `make up p=<名前>`）。
- **認証情報・ポートは `.env`**: 初回に `cp .env.example .env`。値は開発用ダミーなので、LAN/公開環境では必ず変更する（[セキュリティ仕様書](../06-security-specification.md)）。
- **ホストポートは `127.0.0.1` バインド**: `localhost` からは繋がるが、同一 LAN の他端末からは見えない。

```bash
cp .env.example .env                      # 初回のみ
docker compose --profile postgres up -d   # 例: Postgres + Adminer
make up p=postgres                        # 同等のショートカット
docker compose --profile all down         # 停止（データは残る）
```

## ガイド一覧

### Databases（RDB / NoSQL / KVS / ベクトル）

| サービス | 用途 | profile | ホストポート | クライアント |
|---------|------|---------|-------------|-------------|
| [PostgreSQL](./01-postgres.md) | 標準 RDB | `postgres` / `sql` | 5432 | Adminer :8080 |
| [MySQL](./02-mysql.md) | RDB（広く普及） | `mysql` / `sql` | 3306 | Adminer :8080 |
| [MariaDB](./03-mariadb.md) | MySQL 互換 RDB | `mariadb` / `sql` | 3307 | Adminer :8080 |
| [MSSQL](./04-mssql.md) | SQL Server | `mssql` / `sql` | 1433 | Adminer :8080 |
| [pgvector](./05-pgvector.md) | ベクトル検索（RAG） | `pgvector` / `vector` | 5433 | — |
| [MongoDB](./06-mongodb.md) | ドキュメント NoSQL | `mongodb` / `nosql` | 27017 | Mongo Express :8081 |
| [DynamoDB Local](./07-dynamodb.md) | KV/ドキュメント（AWS） | `dynamodb` / `nosql` | 8000 | dynamodb-admin :8001 |
| [Redis](./08-redis.md) | KVS / キャッシュ | `redis` | 6379 | RedisInsight :5540 |

### Storage / Messaging / Mail

| サービス | 用途 | profile | ホストポート | クライアント |
|---------|------|---------|-------------|-------------|
| [MinIO](./09-minio.md) | S3互換オブジェクトストレージ | `minio` / `storage` | 9000 / 9001 | 内蔵コンソール :9001 |
| [Apache Kafka](./10-kafka.md) | イベントストリーミング | `kafka` / `messaging` | 9092 | Kafka UI :8082 |
| [RabbitMQ](./11-rabbitmq.md) | メッセージキュー（AMQP） | `rabbitmq` / `messaging` | 5672 / 15672 | 管理UI :15672 |
| [Mailpit](./12-mailpit.md) | メール送信テスト（SMTP） | `mailpit` | 1025 / 8025 | Web UI :8025 |

### Search / Emulators

| サービス | 用途 | profile | ホストポート | クライアント |
|---------|------|---------|-------------|-------------|
| [OpenSearch](./13-opensearch.md) | 全文検索（ES互換） | `opensearch` / `search` | 9200 | Dashboards :5601 |
| [BigQuery emulator](./14-bigquery.md) | BigQuery ローカル代替 | `bigquery` / `emulator` | 9050 / 9060 | — |
| [LocalStack](./15-localstack.md) | AWS エミュレータ（S3/SQS等） | `localstack` / `emulator` | 4566 | — |

### Monitoring（可観測性3本柱）

| サービス | 用途 | profile | ホストポート | クライアント |
|---------|------|---------|-------------|-------------|
| [Prometheus](./16-prometheus.md) | メトリクス収集 | `prometheus` / `monitoring` | 9090 | 内蔵UI :9090 |
| [Grafana](./17-grafana.md) | 可視化ダッシュボード | `grafana` / `monitoring` | 3000 | Grafana :3000 |
| [Loki](./18-loki.md) | ログ集約 | `loki` / `monitoring` | 3100 | Grafana から参照 |
| [Tempo](./19-tempo.md) | 分散トレース | `tempo` / `monitoring` | 3200 / 4317 / 4318 | Grafana から参照 |

### 付録

| ドキュメント | 内容 |
|---------|------|
| [用語集](./99-glossary.md) | 各ガイドに横断的に出てくる用語（Compose 基礎 / 運用一般 / サービス固有）の逆引き |

> `all` profile は全サービスを起動する。各カテゴリの profile（`sql` / `nosql` / `messaging` / `monitoring` / `search` / `emulator`）でまとめ起動も可能。

## 関連ドキュメント

- [README.md](../../README.md) — テンプレ全体の概要・使い方
- [09 アーキテクチャ仕様書](../09-architecture-specification.md) — 構成・技術スタック・ポート一覧
- [06 セキュリティ仕様書](../06-security-specification.md) — 公開範囲・開発用の緩和点
- [05 データ仕様書](../05-data-specification.md) — pgvector の扱い
