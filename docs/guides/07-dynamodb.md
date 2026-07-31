# DynamoDB Local 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `amazon/dynamodb-local:3.3.0` |
| コンテナ名 | `infra-dynamodb` |
| カテゴリ | NoSQL（キーバリュー / ドキュメント・AWS エミュレータ） |
| profile | `dynamodb` / `nosql` / `all` |
| ホストポート | `8000`（`127.0.0.1` バインド） |
| Web クライアント | dynamodb-admin（http://localhost:8001） |

DynamoDB Local は AWS DynamoDB の **ローカルエミュレータ**。実 AWS に接続せず、DynamoDB の API をローカルで検証できる。`-sharedDb -dbPath` でデータを永続化している。

## 2. 目的・ユースケース

- DynamoDB を使うアプリのローカル開発・CI（AWS 課金なし）
- パーティションキー/ソートキー設計の学習
- AWS SDK のコードを実機を使わずテスト

## 3. 起動方法

```bash
docker compose --profile dynamodb up -d      # DynamoDB Local + dynamodb-admin
make up p=dynamodb
docker compose -f databases/dynamodb/compose.yaml up dynamodb   # 単独
```

- 関連クライアント: **dynamodb-admin** → http://localhost:8001（エンドポイント `http://dynamodb:8000` に自動接続）

## 4. 接続情報

| 接続元 | エンドポイント |
|--------|----------------|
| ホスト PC | `http://localhost:8000` |
| コンテナ間 | `http://dynamodb:8000` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `AWS_REGION` | `ap-northeast-1` | リージョン（ローカルでは任意の値でよい） |
| `AWS_ACCESS_KEY_ID` | `local` | ダミー認証（任意の値でよい） |
| `AWS_SECRET_ACCESS_KEY` | `local` | ダミー認証 |
| `DYNAMODB_PORT` | `8000` | ホスト公開ポート |

- データは `infra-dynamodb-data` に永続化（`-sharedDb -dbPath ./data`）。
- ⚠ AWS SDK は **エンドポイントの明示指定が必須**（指定しないと実 AWS に繋ごうとする）。認証情報はダミーで通る。

## 5. 使用例（CLI / aws cli）

```bash
# テーブル作成（--endpoint-url が肝）
aws dynamodb create-table --endpoint-url http://localhost:8000 \
  --table-name users --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST

aws dynamodb put-item --endpoint-url http://localhost:8000 \
  --table-name users --item '{"id":{"S":"u1"},"name":{"S":"Alice"}}'

aws dynamodb scan --endpoint-url http://localhost:8000 --table-name users
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb
```

```ts
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

const ddb = new DynamoDBClient({
  endpoint: process.env.DDB_ENDPOINT ?? "http://localhost:8000", // コンテナ間は http://dynamodb:8000
  region: "ap-northeast-1",
  credentials: { accessKeyId: "local", secretAccessKey: "local" },
});
const doc = DynamoDBDocumentClient.from(ddb);

await doc.send(new PutCommand({ TableName: "users", Item: { id: "u1", name: "Alice" } }));
const out = await doc.send(new ScanCommand({ TableName: "users" }));
console.log(out.Items);
```

## 7. アプリへの実装（Python）

```bash
pip install boto3
```

```python
import boto3

ddb = boto3.resource(
    "dynamodb",
    endpoint_url="http://localhost:8000",   # コンテナ間は http://dynamodb:8000
    region_name="ap-northeast-1",
    aws_access_key_id="local", aws_secret_access_key="local",
)
table = ddb.Table("users")
table.put_item(Item={"id": "u1", "name": "Alice"})
print(table.scan()["Items"])
```

## 8. つまずきポイント・Tips

- **`endpoint-url` / `endpoint` を必ず指定**: 最頻出ミス。指定しないと SDK は実 AWS に接続し、認証エラーや課金につながる。
- **`localhost` と `dynamodb` の取り違え**: ホストのアプリは `http://localhost:8000`、コンテナ内は `http://dynamodb:8000`。
- **認証情報はダミーで可**: ただし「空」だと SDK がエラーになることがあるため `local` 等を入れる。
- **テーブルは事前作成**: DynamoDB はスキーマレスだがテーブル（とキー定義）は作る必要がある。

## 9. 参考リンク

- DynamoDB Local: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html
- 関連: [localstack ガイド](./15-localstack.md)（S3/SQS/SNS も含む AWS エミュレータ）
