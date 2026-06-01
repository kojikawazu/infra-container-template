# RabbitMQ 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `rabbitmq:4-management`（管理UI内蔵） |
| コンテナ名 | `infra-rabbitmq` |
| カテゴリ | メッセージング（メッセージブローカー / AMQP） |
| profile | `rabbitmq` / `messaging` / `all` |
| ホストポート | AMQP `5672` / 管理UI `15672`（`127.0.0.1` バインド） |
| Web クライアント | 管理UI 内蔵（http://localhost:15672） |

RabbitMQ は AMQP プロトコルのメッセージブローカー。「キュー」にメッセージを溜め、ワーカーが取り出して処理する。タスクキュー・非同期ジョブ・サービス間連携に使う。Kafka が「再読可能なログ」なのに対し、RabbitMQ は「消費したら消える伝統的キュー」。

## 2. 目的・ユースケース

- 非同期ジョブ（メール送信・画像変換などの重い処理を後回し）
- ワーカープール（複数ワーカーで負荷分散）
- ルーティング（exchange でメッセージを振り分け）

## 3. 起動方法

```bash
docker compose --profile rabbitmq up -d      # = --profile messaging（Kafka も上がる）
make up p=messaging
docker compose -f messaging/rabbitmq/compose.yaml up rabbitmq   # 単独
```

- 関連クライアント: **管理UI**（イメージに内蔵）→ http://localhost:15672（`RABBITMQ_USER`/`RABBITMQ_PASSWORD` でログイン）

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC（AMQP） | `localhost` | `5672` |
| コンテナ間（AMQP） | `rabbitmq` | `5672` |
| 管理UI（ブラウザ） | `localhost` | `15672` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `RABBITMQ_USER` | `admin` | ユーザー（既定の guest ではない） |
| `RABBITMQ_PASSWORD` | `adminpass` | パスワード |
| `RABBITMQ_PORT` | `5672` | AMQP ポート |
| `RABBITMQ_MGMT_PORT` | `15672` | 管理UI ポート |

- 接続 URI 例: `amqp://admin:adminpass@localhost:5672`
- データは `infra-rabbitmq-data` に永続化。

## 5. 使用例（CLI / rabbitmqctl）

```bash
docker exec -it infra-rabbitmq rabbitmqctl list_queues      # キュー一覧
docker exec -it infra-rabbitmq rabbitmqctl list_connections # 接続一覧
```

> メッセージの送受信はライブラリ（下記）か管理UI（http://localhost:15672 の "Queues" タブ）で行うのが分かりやすい。

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install amqplib
```

```ts
import amqp from "amqplib";

const conn = await amqp.connect(
  process.env.AMQP_URL ?? "amqp://admin:adminpass@localhost:5672" // コンテナ間は @rabbitmq:5672
);
const ch = await conn.createChannel();
await ch.assertQueue("tasks", { durable: true });

// 送信
ch.sendToQueue("tasks", Buffer.from("job-1"), { persistent: true });

// 受信
await ch.consume("tasks", (msg) => {
  if (msg) {
    console.log("received:", msg.content.toString());
    ch.ack(msg);
  }
});
```

## 7. アプリへの実装（Python）

```bash
pip install pika
```

```python
import pika

params = pika.URLParameters("amqp://admin:adminpass@localhost:5672")  # コンテナ間は @rabbitmq:5672
conn = pika.BlockingConnection(params)
ch = conn.channel()
ch.queue_declare(queue="tasks", durable=True)

# 送信
ch.basic_publish(exchange="", routing_key="tasks", body=b"job-1")

# 受信（1件取り出して確認）
method, props, body = ch.basic_get(queue="tasks", auto_ack=True)
print(body)
conn.close()
```

## 8. つまずきポイント・Tips

- **ユーザーは guest ではない**: 本テンプレは `.env` の `admin`/`adminpass`。既定の `guest`/`guest` は使えない（かつ guest はリモート接続不可）。
- **`localhost` と `rabbitmq` の取り違え**: ホストのアプリは `localhost:5672`、コンテナ内は `rabbitmq:5672`。
- **`durable` と `persistent`**: キューを `durable`、メッセージを `persistent` にしないと再起動で消える。
- **ack を忘れない**: 受信後 `ack` しないとメッセージが「未処理」のまま再配信される。

## 9. 参考リンク

- 公式ドキュメント: https://www.rabbitmq.com/documentation.html
- 関連: [kafka ガイド](./10-kafka.md)（大規模ストリーミング）
