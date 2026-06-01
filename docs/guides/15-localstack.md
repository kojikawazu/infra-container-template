# LocalStack (AWS エミュレータ) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `localstack/localstack:3`（Community 版・無料） |
| コンテナ名 | `infra-localstack` |
| カテゴリ | エミュレータ（AWS マルチサービスのローカル代替） |
| profile | `localstack` / `emulator` / `all` |
| ホストポート | `4566`（統合エンドポイント・`127.0.0.1` バインド） |
| Web クライアント | なし（`aws --endpoint-url` / SDK で操作） |

LocalStack は多数の AWS サービス（S3・SQS・SNS・DynamoDB 等）を**1つの統合エンドポイント `:4566`** でローカル模倣する。実 AWS に接続せず、複数 AWS サービスを跨ぐアプリを検証できる。既定で `s3,sqs,sns,dynamodb` を有効化。

## 2. 目的・ユースケース

- 複数 AWS サービスを使うアプリのローカル開発・CI（AWS 課金なし）
- S3 + SQS + SNS を組み合わせたイベント駆動の検証
- AWS SDK / IaC（Terraform 等）の動作確認

## 3. 起動方法

```bash
docker compose --profile localstack up -d    # = --profile emulator（BigQuery も上がる）
make up p=emulator
docker compose -f emulators/localstack/compose.yaml up localstack   # 単独
```

## 4. 接続情報

| 接続元 | 統合エンドポイント |
|--------|--------------------|
| ホスト PC | `http://localhost:4566` |
| コンテナ間 | `http://localstack:4566` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `LOCALSTACK_PORT` | `4566` | 統合エンドポイント |
| `LOCALSTACK_SERVICES` | `s3,sqs,sns,dynamodb` | 有効化する AWS サービス |
| `LOCALSTACK_DEBUG` | `0` | デバッグログ |
| `LOCALSTACK_AUTH_TOKEN` | （空） | `:latest`(4系) を使う場合のみ必要 |

- 全サービスが `:4566` を共有（DynamoDB Local と違い個別ポート不要）。認証情報はダミー（`test`/`test` 等）で通る。

## 5. 使用例（CLI / aws cli）

```bash
# S3
aws --endpoint-url http://localhost:4566 s3 mb s3://my-bucket
aws --endpoint-url http://localhost:4566 s3 ls

# SQS
aws --endpoint-url http://localhost:4566 sqs create-queue --queue-name my-queue
aws --endpoint-url http://localhost:4566 sqs list-queues

# ヘルスチェック（有効サービスの状態）
curl http://localhost:4566/_localstack/health
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install @aws-sdk/client-s3 @aws-sdk/client-sqs
```

```ts
import { S3Client, CreateBucketCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({
  endpoint: process.env.AWS_ENDPOINT ?? "http://localhost:4566", // コンテナ間は http://localstack:4566
  region: "us-east-1",
  credentials: { accessKeyId: "test", secretAccessKey: "test" },
  forcePathStyle: true, // S3 はパス形式
});
await s3.send(new CreateBucketCommand({ Bucket: "my-bucket" }));
```

## 7. アプリへの実装（Python）

```bash
pip install boto3
```

```python
import boto3

sqs = boto3.client(
    "sqs",
    endpoint_url="http://localhost:4566",   # コンテナ間は http://localstack:4566
    region_name="us-east-1",
    aws_access_key_id="test", aws_secret_access_key="test",
)
url = sqs.create_queue(QueueName="my-queue")["QueueUrl"]
sqs.send_message(QueueUrl=url, MessageBody="hello")
print(sqs.receive_message(QueueUrl=url).get("Messages"))
```

## 8. つまずきポイント・Tips

- **`endpoint-url` を必ず指定**: 指定しないと実 AWS に接続する。全サービスが `:4566` 共通。
- **`SERVICES` に含めたものだけ使える**: 既定は `s3,sqs,sns,dynamodb`。他サービスは `.env` の `LOCALSTACK_SERVICES` に追加する。
- **Lambda は docker.sock が必要（既定無効）**: ⚠ Lambda 実行にはコンテナからホストの Docker を操作する `docker.sock` マウントが必要。これは**実質ホスト権限**になるため compose で既定無効。必要時のみ opt-in する（[docs/06](../06-security-specification.md)）。
- **3系にピン留め**: `:latest`(4系以降) は無料でも `LOCALSTACK_AUTH_TOKEN`（無料登録）が必須。サインアップ不要にするため 3 系固定。
- **S3 は `forcePathStyle: true`**: MinIO と同様、パス形式が必要。

## 9. 参考リンク

- 公式ドキュメント: https://docs.localstack.cloud/
- 関連: [dynamodb ガイド](./07-dynamodb.md) / [minio ガイド](./09-minio.md) / [セキュリティ仕様書](../06-security-specification.md)
