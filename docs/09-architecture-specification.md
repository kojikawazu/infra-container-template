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
| MSSQL | `mcr.microsoft.com/mssql/server:2022-latest` |
| MySQL | `mysql:8.4` |
| MariaDB | `mariadb:11.4` |
| PostgreSQL | `postgres:17` |
| MongoDB | `mongo:7` |
| DynamoDB Local | `amazon/dynamodb-local:latest` |
| Redis | `redis:7-alpine` |
| MinIO (S3互換) | `minio/minio:latest` |
| Kafka | `apache/kafka:latest` |
| RabbitMQ | `rabbitmq:4-management` |
| BigQuery emulator | `ghcr.io/goccy/bigquery-emulator:latest` |
| LocalStack (AWS) | `localstack/localstack:3`（:latest は無料でも auth token 必須のため固定） |
| Prometheus | `prom/prometheus:latest` |
| Grafana | `grafana/grafana:latest` |
| Adminer | `adminer:latest` |
| Mongo Express | `mongo-express:1.0.2` |
| dynamodb-admin | `aaronshaf/dynamodb-admin:latest` |
| RedisInsight | `redis/redisinsight:latest` |
| Kafka UI | `provectuslabs/kafka-ui:latest` |

> MinIO / Kafka / BigQuery emulator / LocalStack はローカル動作の OSS・エミュレータで、実クラウドに接続せず課金は発生しない（LocalStack は無料の Community 版）。

オーケストレーション: Docker Compose v2.20+（`include` 機能）。

## インフラ構成

- ローカル開発機の Docker Engine 上で動作。外部クラウド依存なし。
- ネットワーク `infra-net`（bridge）、各 DB は名前付きボリューム。
- 認証情報・ポートは `.env`（`.env.example` をコピー）で集中管理。`.env` は Git 管理外。

## デプロイ / CI-CD

<!-- 本テンプレはローカル検証が主目的。CI 連携が必要なら起動方法・ヘルスチェック待機を記述する -->

## 補足: ポート割り当て

| サービス | ホストポート |
|---------|-------------|
| MSSQL | 1433 |
| MySQL | 3306 |
| PostgreSQL | 5432 |
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
| Prometheus | 9090 |
| Grafana | 3000 |
