# infra-container-template

練習・検証・テンプレ用のインフラコンテナ群（RDB / NoSQL / KVS / ベクトルDB / メッセージング / 検索 / オブジェクトストレージ / 監視 / クラウドエミュレータ）と、各サービスを覗く Web クライアントを Docker Compose で一括管理するテンプレート。

## 概要

- 各サービスは `<カテゴリ>/<名前>/compose.yaml` に独立記述。ルートの `compose.yaml` が `include` で束ねる。
- **単一composeでまとめて** も **個別composeで単体** でも起動できる（定義は二重管理なし）。
- `profile` で「必要なサービス + そのクライアント」だけを選択起動。
- 全コンテナが共有ネットワーク `infra-net` に参加し、クライアントはサービス名で解決する。
- **ホストポートは `127.0.0.1` バインド**。`localhost` からは従来どおり接続でき、同一LAN上の他端末からは見えない（[docs/06-security-specification.md](docs/06-security-specification.md) 参照）。

| サービス | クライアント (Web UI) | profile |
|----|----------------------|---------|
| MSSQL (1433) | Adminer → http://localhost:8080 | `mssql` `sql` `all` |
| MySQL (3306) | Adminer → http://localhost:8080 | `mysql` `sql` `all` |
| MariaDB (3307) | Adminer → http://localhost:8080 | `mariadb` `sql` `all` |
| PostgreSQL (5432) | Adminer → http://localhost:8080 | `postgres` `sql` `all` |
| pgvector (5433) | — (psql / クライアントライブラリ) | `pgvector` `vector` `all` |
| MongoDB (27017) | Mongo Express → http://localhost:8081 | `mongodb` `nosql` `all` |
| DynamoDB Local (8000) | dynamodb-admin → http://localhost:8001 | `dynamodb` `nosql` `all` |
| Redis (6379) | RedisInsight → http://localhost:5540 | `redis` `all` |
| OpenSearch (9200) | OpenSearch Dashboards → http://localhost:5601 | `opensearch` `search` `all` |
| MinIO / S3互換 (9000) | 内蔵コンソール → http://localhost:9001 | `minio` `storage` `all` |
| Kafka (9092) | Kafka UI → http://localhost:8082 | `kafka` `messaging` `all` |
| RabbitMQ (5672) | 管理UI内蔵 → http://localhost:15672 | `rabbitmq` `messaging` `all` |
| Mailpit (SMTP 1025) | http://localhost:8025 | `mailpit` `all` |
| Prometheus (9090) | (Web UI 内蔵) | `prometheus` `monitoring` `all` |
| Grafana (3000) | http://localhost:3000（データソース自動登録）| `grafana` `monitoring` `all` |
| Loki (3100) | Grafana から参照（ログ）| `loki` `monitoring` `all` |
| Tempo (3200 / OTLP 4317・4318) | Grafana から参照（トレース）| `tempo` `monitoring` `all` |
| BigQuery emulator (REST 9050 / gRPC 9060) | — (クライアントライブラリ) | `bigquery` `emulator` `all` |
| LocalStack / AWS (4566) | — (`aws --endpoint-url`) | `localstack` `emulator` `all` |

> OpenSearch / MinIO / Kafka / Mailpit / Loki / Tempo / BigQuery emulator / LocalStack はすべて**ローカル動作の無料 OSS / エミュレータ**。実クラウドには接続せず課金は発生しない（OpenSearch は Apache-2.0、LocalStack は Community 版）。

## セットアップ

前提: Docker Engine + Docker Compose v2.20 以上（`include` 機能を使用）。

```bash
cp .env.example .env   # 認証情報・ポートを必要に応じて編集
```

## 使い方

### まとめて起動（profile で選択）

profile 未指定では何も起動しない（意図的な選択を強制）。

```bash
docker compose --profile postgres up -d   # Postgres + Adminer
docker compose --profile sql up -d        # MSSQL/MySQL/PostgreSQL + Adminer
docker compose --profile nosql up -d      # MongoDB/DynamoDB + 各GUI
docker compose --profile storage up -d    # MinIO
docker compose --profile messaging up -d  # Kafka + Kafka UI + RabbitMQ
docker compose --profile mailpit up -d    # Mailpit (メール送信テスト)
docker compose --profile search up -d     # OpenSearch + Dashboards
docker compose --profile vector up -d     # pgvector
docker compose --profile emulator up -d   # BigQuery / LocalStack
docker compose --profile monitoring up -d # Prometheus + Grafana + Loki + Tempo
docker compose --profile all up -d        # 全部

docker compose --profile all down         # 停止＆削除（データは残る）
docker compose --profile all down -v      # データごと完全削除
```

Makefile のショートカットも利用可:

```bash
make up p=postgres   # = docker compose --profile postgres up -d
make logs p=mysql    # ログ追従
make ps              # 起動中一覧
make clean           # データごと削除
```

### 個別 compose で単体起動

ルートディレクトリから `-f` で対象ファイルを指定（`.env` はそのまま使われる）:

```bash
docker compose -f databases/mysql/compose.yaml up mysql
docker compose -f clients/adminer/compose.yaml up adminer
```

### クライアントからの接続情報

| クライアント | 接続先ホスト | 補足 |
|---|---|---|
| Adminer | `mssql` / `mysql` / `postgres` | ログイン画面の「サーバ」にサービス名を入力 |
| Mongo Express | 自動接続 | Basic認証 `MONGO_EXPRESS_USER` / `_PASSWORD`（既定 admin/admin） |
| dynamodb-admin | 自動接続 | エンドポイント `http://dynamodb:8000` |
| RedisInsight | `redis` (6379) | DB追加時に `REDIS_PASSWORD` を入力 |
| OpenSearch Dashboards | 自動接続 | 接続先 `http://opensearch:9200`（開発用にセキュリティ無効） |
| pgvector | `pgvector` (5432) | アプリからは `pgvector:5432`、ホストからは `localhost:5433` |
| Mailpit | SMTP `mailpit:1025` | アプリの SMTP 送信先に指定。受信は http://localhost:8025 |

> コンテナ間はサービス名（`mysql` 等）で接続、ホスト PC からは `localhost:<ポート>` で接続する。

### CLI で覗く（GUI 不要な場合）

```bash
docker exec -it infra-postgres psql -U appuser -d appdb
docker exec -it infra-mysql mysql -u appuser -p appdb
docker exec -it infra-redis redis-cli -a redispass
docker exec -it infra-mongodb mongosh -u root -p rootpass
```

## ディレクトリ構成

```
.
├── compose.yaml              # include で全composeを束ねる
├── .env.example              # 認証情報・ポート定義
├── Makefile                  # 操作ショートカット
├── databases/
│   ├── mssql/  mysql/  mariadb/  postgres/  mongodb/  dynamodb/  redis/  pgvector/
│   │   └── compose.yaml      # 各DB（単独起動可）
│   ├── {mysql,mariadb,postgres}/initdb/   # 初回起動時に実行する *.sql / *.sh
│   └── pgvector/initdb/      # vector 拡張を有効化（テンプレ提供スクリプト）
├── storage/minio/            # S3互換オブジェクトストレージ
├── messaging/                # kafka/  rabbitmq/  メッセージング
├── mail/mailpit/             # メール送信テスト（SMTP受信→Web UI）
├── search/opensearch/        # 全文検索エンジン（Elasticsearch互換）
├── emulators/                # bigquery/  localstack/  クラウドエミュレータ
├── monitoring/               # prometheus/  grafana/  loki/  tempo/  監視（自動プロビジョニング）
├── scripts/validate-compose.sh  # 構成検証テスト
└── clients/
    └── adminer/  mongo-express/  dynamodb-admin/  redisinsight/  kafka-ui/  opensearch-dashboards/
        └── compose.yaml      # 各クライアント
```

詳細な設計は [docs/09-architecture-specification.md](docs/09-architecture-specification.md) を参照。

## 学習ガイド（コンテナ別）

各サービスの「概要・目的・起動・接続・使用例・アプリ実装（CLI / TypeScript / Python）」を 1 サービス 1 ファイルでまとめた学習用ドキュメントを用意している。
まずは [docs/guides/00-index.md](docs/guides/00-index.md) から目的のコンテナを選ぶ。
