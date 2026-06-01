# MinIO (S3互換オブジェクトストレージ) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `minio/minio:latest` |
| コンテナ名 | `infra-minio` |
| カテゴリ | オブジェクトストレージ（S3 互換） |
| profile | `minio` / `storage` / `all` |
| ホストポート | API `9000` / コンソール `9001`（`127.0.0.1` バインド） |
| Web クライアント | MinIO 内蔵コンソール（http://localhost:9001） |

MinIO は Amazon S3 互換 API を持つ OSS のオブジェクトストレージ。画像・動画・バックアップ・ログなどの非構造化データを「バケット」に保存する。S3 SDK のコードをそのまま使える。

## 2. 目的・ユースケース

- S3 を使うアプリのローカル開発（AWS 課金なし）
- ファイルアップロード機能の検証（画像・添付ファイル）
- S3 SDK / 署名付き URL の学習

## 3. 起動方法

```bash
docker compose --profile minio up -d         # = --profile storage
make up p=storage
docker compose -f storage/minio/compose.yaml up minio   # 単独
```

- 関連クライアント: **内蔵コンソール** → http://localhost:9001（`MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` でログイン）。ここでバケット作成・ファイル閲覧ができる。

## 4. 接続情報

| 接続元 | エンドポイント（API） |
|--------|----------------------|
| ホスト PC | `http://localhost:9000` |
| コンテナ間 | `http://minio:9000` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MINIO_ROOT_USER` | `minioadmin` | アクセスキー（管理者） |
| `MINIO_ROOT_PASSWORD` | `minioadmin` | シークレットキー |
| `MINIO_API_PORT` | `9000` | S3 API ポート |
| `MINIO_CONSOLE_PORT` | `9001` | Web コンソールポート |

- データは `infra-minio-data` に永続化。
- ⚠ S3 SDK では **`forcePathStyle`（パス形式）と `endpoint` の指定が必須**。MinIO は仮想ホスト形式に未対応のため。

## 5. 使用例（CLI / aws cli）

```bash
# AWS CLI を MinIO に向ける（認証は ROOT_USER/PASSWORD）
aws --endpoint-url http://localhost:9000 s3 mb s3://my-bucket
echo "hello" > hello.txt
aws --endpoint-url http://localhost:9000 s3 cp hello.txt s3://my-bucket/
aws --endpoint-url http://localhost:9000 s3 ls s3://my-bucket/
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install @aws-sdk/client-s3
```

```ts
import { S3Client, CreateBucketCommand, PutObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";

const s3 = new S3Client({
  endpoint: process.env.S3_ENDPOINT ?? "http://localhost:9000", // コンテナ間は http://minio:9000
  region: "us-east-1",
  credentials: { accessKeyId: "minioadmin", secretAccessKey: "minioadmin" },
  forcePathStyle: true, // MinIO では必須
});

await s3.send(new CreateBucketCommand({ Bucket: "my-bucket" }));
await s3.send(new PutObjectCommand({ Bucket: "my-bucket", Key: "hello.txt", Body: "hello" }));
const list = await s3.send(new ListObjectsV2Command({ Bucket: "my-bucket" }));
console.log(list.Contents);
```

## 7. アプリへの実装（Python）

```bash
pip install boto3
```

```python
import boto3

s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:9000",   # コンテナ間は http://minio:9000
    aws_access_key_id="minioadmin", aws_secret_access_key="minioadmin",
    region_name="us-east-1",
)
s3.create_bucket(Bucket="my-bucket")
s3.put_object(Bucket="my-bucket", Key="hello.txt", Body=b"hello")
print([o["Key"] for o in s3.list_objects_v2(Bucket="my-bucket").get("Contents", [])])
```

## 8. つまずきポイント・Tips

- **`forcePathStyle: true` を忘れると失敗**: 最頻出ミス。MinIO はパス形式（`endpoint/bucket/key`）のみ対応。
- **`endpoint` の指定必須**: 指定しないと実 AWS S3 に繋がる。
- **API 9000 と コンソール 9001 は別物**: SDK は 9000、ブラウザで覗くのは 9001。
- **`localhost` と `minio` の取り違え**: ホストのアプリは `http://localhost:9000`、コンテナ内は `http://minio:9000`。

## 9. 参考リンク

- 公式ドキュメント: https://min.io/docs/minio/linux/index.html
- 関連: [localstack ガイド](./15-localstack.md)（S3 含む AWS エミュレータ）
