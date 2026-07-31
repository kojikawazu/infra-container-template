# 09. アーキテクチャ仕様書

システム構成・技術スタック・インフラ・デプロイ方針を定義する。

## システム構成

DB コンテナ群 + 各 DB を覗く Web クライアントの2レイヤー構成。Docker Compose で管理する。

```
┌─────────────────────── network: infra-net ───────────────────────┐
│                                                                   │
│  [DB]                          [Client (Web UI)]                  │
│  mssql    1433  ─┐                                                │
│  mysql    3306  ─┼──────────►  adminer        :8080              │
│  postgres 5432  ─┘                                                │
│  mongodb  27017 ───────────►  mongo-express   :8081              │
│  dynamodb 8000  ───────────►  dynamodb-admin  :8001              │
│  redis    6379  ───────────►  redisinsight    :5540              │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
   ホスト PC からは localhost:<ポート>、コンテナ間はサービス名で接続
```

- **compose 分割**: 各 DB / クライアントを `databases/<db>/compose.yaml` `clients/<name>/compose.yaml` に独立記述。
- **集約**: ルート `compose.yaml` が `include` で全ファイルを束ねる（単一composeと個別composeを二重管理なしで両立）。
- **共有ネットワーク**: 全 compose が `name: infra-net` を明示宣言。Docker ネットワーク名はグローバルなため、どの起動方法でも同一ネットワークに合流する（`docker network create` の事前作成は不要）。
- **profile による選択起動**: 各サービスに DB 単位（`mysql` 等）＋グループ（`sql` / `nosql` / `all`）の profile を付与。profile 未指定では何も起動しない。
- **永続化**: 各 DB は名前付きボリューム（`infra-<db>-data`）に永続化。

## 技術スタック

| 種別 | イメージ |
|------|---------|
| MSSQL | `mcr.microsoft.com/mssql/server:2022-CU26-ubuntu-22.04` |
| MySQL | `mysql:8.4` |
| MariaDB | `mariadb:11.4` |
| PostgreSQL | `postgres:17` |
| MongoDB | `mongo:7` |
| DynamoDB Local | `amazon/dynamodb-local:3.3.0` |
| Redis | `redis:7-alpine` |
| pgvector | `pgvector/pgvector:pg17`（postgres17 + vector 拡張） |
| MinIO (S3互換) | `minio/minio:RELEASE.2025-09-07T16-13-09Z` |
| Kafka | `apache/kafka:4.3.1` |
| RabbitMQ | `rabbitmq:4-management` |
| Mailpit | `axllent/mailpit:v1.30.6` |
| OpenSearch | `opensearchproject/opensearch:2.17.1` |
| BigQuery emulator | `ghcr.io/goccy/bigquery-emulator:0.8.1` |
| LocalStack (AWS) | `localstack/localstack:3`（:latest は無料でも auth token 必須のため固定） |
| Prometheus | `prom/prometheus:v3.13.2` |
| Grafana | `grafana/grafana:13.1.1` |
| Loki | `grafana/loki:3.1.1` |
| Tempo | `grafana/tempo:2.6.1` |
| Adminer | `adminer:5.5.0` |
| Mongo Express | `mongo-express:1.0.2` |
| dynamodb-admin | `aaronshaf/dynamodb-admin:5.3.4` |
| RedisInsight | `redis/redisinsight:3.8.0` |
| Kafka UI | `provectuslabs/kafka-ui:v0.7.2` |
| OpenSearch Dashboards | `opensearchproject/opensearch-dashboards:2.17.1` |

> OpenSearch / MinIO / Kafka / Mailpit / Loki / Tempo / BigQuery emulator / LocalStack はローカル動作の OSS・エミュレータで、実クラウドに接続せず課金は発生しない（OpenSearch は Apache-2.0、LocalStack は無料の Community 版）。

オーケストレーション: Docker Compose v2.20+（`include` 機能）。

## インフラ構成

- ローカル開発機の Docker Engine 上で動作。外部クラウド依存なし。
- ネットワーク `infra-net`（bridge）、各 DB は名前付きボリューム。
- 認証情報・ポートは `.env`（`.env.example` をコピー）で集中管理。`.env` は Git 管理外。
- **ホストポートは全サービス `127.0.0.1` バインド**。`localhost` からの接続は不変で、同一LAN上の他端末からはアクセス不可（詳細は docs/06）。
- **可観測性 (Observability)**: メトリクス(Prometheus) / ログ(Loki) / トレース(Tempo) の3本柱を Grafana に集約。データソースは起動時に自動プロビジョニング。アプリは OTLP(4317/4318) で Tempo にトレースを送れる。
- **役割分離**: ベクトル検索は通常 postgres と別コンテナ(`pgvector`・ポート5433)に分離し、業務DBと資源/責務を混在させない。

## デプロイ / CI-CD

<!-- 本テンプレはローカル検証が主目的。CI 連携が必要なら起動方法・ヘルスチェック待機を記述する -->

## 補足: ポート割り当て

| サービス | ホストポート |
|---------|-------------|
| MSSQL | 1433 |
| MySQL | 3306 |
| PostgreSQL | 5432 |
| pgvector | 5433 |
| MongoDB | 27017 |
| DynamoDB Local | 8000 |
| Redis | 6379 |
| Adminer | 8080 |
| Mongo Express | 8081 |
| dynamodb-admin | 8001 |
| RedisInsight | 5540 |
| MinIO API / Console | 9000 / 9001 |
| MariaDB | 3307 |
| Kafka | 9092 |
| Kafka UI | 8082 |
| RabbitMQ AMQP / 管理UI | 5672 / 15672 |
| BigQuery emulator REST / gRPC | 9050 / 9060 |
| LocalStack | 4566 |
| Mailpit SMTP / Web UI | 1025 / 8025 |
| OpenSearch | 9200 |
| OpenSearch Dashboards | 5601 |
| Prometheus | 9090 |
| Grafana | 3000 |
| Loki | 3100 |
| Tempo HTTP / OTLP gRPC / OTLP HTTP | 3200 / 4317 / 4318 |

> 全ポートはホスト側 `127.0.0.1` にバインドする（例: `127.0.0.1:5432:5432`）。
