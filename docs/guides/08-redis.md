# Redis 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `redis:7-alpine` |
| コンテナ名 | `infra-redis` |
| カテゴリ | KVS（インメモリ・キーバリューストア） |
| profile | `redis` / `all` |
| ホストポート | `6379`（`127.0.0.1` バインド） |
| Web クライアント | RedisInsight（http://localhost:5540） |

Redis はメモリ上で動く超高速な KVS。文字列・ハッシュ・リスト・セット・ソート済みセットなどのデータ構造を持つ。キャッシュ・セッション・キュー・レートリミットに使う。本テンプレでは `requirepass` で認証、`appendonly yes` で永続化している。

## 2. 目的・ユースケース

- **キャッシュ**: DB クエリ結果や API レスポンスの一時保存
- **セッションストア**: ログインセッションの共有
- **キュー / Pub-Sub**: 軽量なジョブキュー・リアルタイム通知
- レートリミット・カウンタ（`INCR`）

## 3. 起動方法

```bash
docker compose --profile redis up -d         # Redis + RedisInsight
make up p=redis
docker compose -f databases/redis/compose.yaml up redis   # 単独
```

- 関連クライアント: **RedisInsight** → http://localhost:5540（DB 追加時にホスト `redis`・ポート 6379・`REDIS_PASSWORD` を入力）

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `6379` |
| コンテナ間 | `redis` | `6379` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `REDIS_PASSWORD` | `redispass` | 認証パスワード（`requirepass`） |
| `REDIS_PORT` | `6379` | ホスト公開ポート |

- 接続 URI 例: `redis://:redispass@localhost:6379`
- データは `infra-redis-data` に永続化（AOF）。

## 5. 使用例（CLI / redis-cli）

```bash
docker exec -it infra-redis redis-cli -a redispass
```

```
SET greeting "hello"
GET greeting
INCR counter
EXPIRE greeting 60      # 60秒で失効
HSET user:1 name Alice age 30
HGETALL user:1
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install ioredis
```

```ts
import Redis from "ioredis";

const redis = new Redis({
  host: process.env.REDIS_HOST ?? "localhost", // コンテナ間は "redis"
  port: 6379,
  password: "redispass",
});

await redis.set("greeting", "hello", "EX", 60); // 60秒TTL
console.log(await redis.get("greeting"));        // "hello"
await redis.incr("counter");
redis.disconnect();
```

## 7. アプリへの実装（Python）

```bash
pip install redis
```

```python
import redis

r = redis.Redis(
    host="localhost", port=6379,    # コンテナ間は host="redis"
    password="redispass", decode_responses=True,
)
r.set("greeting", "hello", ex=60)   # 60秒TTL
print(r.get("greeting"))            # "hello"
r.incr("counter")
```

## 8. つまずきポイント・Tips

- **パスワードを忘れない**: `requirepass` で保護しているため、認証なしの接続は `NOAUTH` エラーになる。
- **`localhost` と `redis` の取り違え**: ホストのアプリは `localhost:6379`、コンテナ内は `redis:6379`。
- **TTL を活用**: キャッシュ用途では `EX`（秒）/ `PX`（ミリ秒）で失効時間を設定し、メモリ肥大を防ぐ。
- **永続化方式**: 本テンプレは AOF（`appendonly`）。再起動してもデータは残るが、Redis は基本「揮発前提」で設計するのが安全。

## 9. 参考リンク

- 公式ドキュメント: https://redis.io/docs/
- Docker イメージ: https://hub.docker.com/_/redis
