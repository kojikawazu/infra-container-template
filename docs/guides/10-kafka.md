# Apache Kafka 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `apache/kafka:latest`（KRaft・単一ノード） |
| コンテナ名 | `infra-kafka` |
| カテゴリ | メッセージング（分散イベントストリーミング） |
| profile | `kafka` / `messaging` / `all` |
| ホストポート | `9092`（`127.0.0.1` バインド） |
| Web クライアント | Kafka UI（http://localhost:8082） |

Kafka は大規模なイベント/ログを「トピック」に追記し、複数のコンシューマが順序を保って読むための分散ストリーミング基盤。マイクロサービス間の非同期連携・ログ収集・イベントソーシングに使う。本テンプレは ZooKeeper 不要の **KRaft モード単一ノード**。

## 2. 目的・ユースケース

- マイクロサービス間の非同期イベント連携
- ログ/メトリクス/クリックストリームの収集パイプライン
- イベントソーシング・CQRS の学習
- Pub-Sub と異なり「再読み込み可能なログ」が必要なケース

## 3. 起動方法

```bash
docker compose --profile kafka up -d         # = --profile messaging（RabbitMQ も上がる）
make up p=messaging
docker compose -f messaging/kafka/compose.yaml up kafka   # 単独
```

- 関連クライアント: **Kafka UI** → http://localhost:8082（トピック・メッセージ・コンシューマグループを GUI で確認）

## 4. 接続情報（重要: 2つのリスナー）

| 接続元 | ブートストラップサーバ |
|--------|------------------------|
| ホスト PC | `localhost:9092` |
| コンテナ間（同一 `infra-net`） | `kafka:19092` |

> ⚠ **最重要**: Kafka は接続元によって広告アドレス（advertised listener）が異なる。
> - ホスト PC のアプリ → `localhost:9092`
> - 同じネットワーク上のコンテナ（Kafka UI 含む）→ `kafka:19092`
> コンテナから `localhost:9092` を指定すると繋がらない。

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `KAFKA_PORT` | `9092` | ホスト公開ポート |
| `KAFKA_UI_PORT` | `8082` | Kafka UI ポート |

- ⚠ 本テンプレはログを **永続化していない**（ephemeral）。コンテナ削除でメッセージは消える。永続化が必要なら `KAFKA_LOG_DIRS` + volume を追加する。
- 開発用に **PLAINTEXT**（認証なし）。LAN へ公開する場合は SASL 等を付与する（[docs/06](../06-security-specification.md)）。

## 5. 使用例（CLI / コンテナ内ツール）

```bash
# トピック作成
docker exec -it infra-kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --create --topic demo --partitions 1

# プロデュース（入力後 Ctrl-C）
docker exec -it infra-kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 --topic demo

# コンシューム（先頭から）
docker exec -it infra-kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic demo --from-beginning
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install kafkajs
```

```ts
import { Kafka } from "kafkajs";

const kafka = new Kafka({
  clientId: "demo-app",
  brokers: [process.env.KAFKA_BROKER ?? "localhost:9092"], // コンテナ間は "kafka:19092"
});

const producer = kafka.producer();
await producer.connect();
await producer.send({ topic: "demo", messages: [{ value: "hello" }] });
await producer.disconnect();

const consumer = kafka.consumer({ groupId: "demo-group" });
await consumer.connect();
await consumer.subscribe({ topic: "demo", fromBeginning: true });
await consumer.run({
  eachMessage: async ({ message }) => console.log(message.value?.toString()),
});
```

## 7. アプリへの実装（Python）

```bash
pip install kafka-python
```

```python
from kafka import KafkaProducer, KafkaConsumer

# コンテナ間は bootstrap_servers="kafka:19092"
producer = KafkaProducer(bootstrap_servers="localhost:9092")
producer.send("demo", b"hello")
producer.flush()

consumer = KafkaConsumer(
    "demo", bootstrap_servers="localhost:9092",
    auto_offset_reset="earliest", group_id="demo-group",
)
for msg in consumer:
    print(msg.value)
    break
```

## 8. つまずきポイント・Tips

- **リスナーの使い分けが全て**: ホスト=`localhost:9092` / コンテナ=`kafka:19092`。ここを間違えるとタイムアウトで繋がらない。
- **データは消える**: 永続化していないため、検証データはコンテナ削除で失われる。
- **コンシューマグループとオフセット**: 同じ `groupId` は負荷分散、異なる `groupId` は各自が全件読む。`fromBeginning`/`earliest` で先頭から読める。
- **トピックは自動作成される設定だが**: 明示作成（CLI/UI）したほうが意図が明確。

## 9. 参考リンク

- 公式ドキュメント: https://kafka.apache.org/documentation/
- 関連: [rabbitmq ガイド](./11-rabbitmq.md)（軽量なメッセージキュー）
