# MongoDB 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `mongo:7` |
| コンテナ名 | `infra-mongodb` |
| カテゴリ | NoSQL（ドキュメント指向DB） |
| profile | `mongodb` / `nosql` / `all` |
| ホストポート | `27017`（`127.0.0.1` バインド） |
| Web クライアント | Mongo Express（http://localhost:8081） |

MongoDB は JSON 風のドキュメント（BSON）を格納する NoSQL DB。スキーマレスで柔軟、ネストした構造をそのまま保存できる。

## 2. 目的・ユースケース

- スキーマが流動的なデータ（ログ・設定・イベント）
- ネストした JSON をそのまま扱いたいアプリ
- プロトタイピング（スキーマ定義を後回しにできる）

## 3. 起動方法

```bash
docker compose --profile mongodb up -d       # MongoDB + Mongo Express
make up p=mongodb
docker compose -f databases/mongodb/compose.yaml up mongodb   # 単独
```

- 関連クライアント: **Mongo Express** → http://localhost:8081（Basic認証 `MONGO_EXPRESS_USER`/`_PASSWORD`、既定 `admin`/`admin`）。MongoDB へは自動接続。

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `27017` |
| コンテナ間 | `mongodb` | `27017` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MONGO_ROOT_USERNAME` | `root` | 管理者ユーザー |
| `MONGO_ROOT_PASSWORD` | `rootpass` | 管理者パスワード |
| `MONGO_DATABASE` | `appdb` | 初期DB名 |
| `MONGO_PORT` | `27017` | ホスト公開ポート |

- 接続 URI 例: `mongodb://root:rootpass@localhost:27017/?authSource=admin`
- データは `infra-mongodb-data` に永続化。

## 5. 使用例（CLI / mongosh）

```bash
docker exec -it infra-mongodb mongosh -u root -p rootpass
```

```javascript
use appdb
db.users.insertMany([{ name: "Alice" }, { name: "Bob" }])
db.users.find({ name: "Alice" })
db.users.countDocuments()
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install mongodb
```

```ts
import { MongoClient } from "mongodb";

// コンテナ間は host を "mongodb" に。authSource=admin を忘れない。
const uri =
  process.env.MONGO_URI ??
  "mongodb://root:rootpass@localhost:27017/?authSource=admin";
const client = new MongoClient(uri);

await client.connect();
const users = client.db("appdb").collection("users");
await users.insertOne({ name: "Alice", createdAt: new Date() });
console.log(await users.find().toArray());
await client.close();
```

## 7. アプリへの実装（Python）

```bash
pip install pymongo
```

```python
from pymongo import MongoClient

# コンテナ間は host を "mongodb" に
client = MongoClient("mongodb://root:rootpass@localhost:27017/?authSource=admin")
users = client["appdb"]["users"]
users.insert_one({"name": "Alice"})
print(list(users.find({}, {"_id": 0})))
client.close()
```

## 8. つまずきポイント・Tips

- **`authSource=admin` が必須**: ルートユーザーは `admin` DB に作られる。接続 URI に付けないと認証エラーになる。
- **`localhost` と `mongodb` の取り違え**: ホストのアプリは `localhost:27017`、コンテナ内は `mongodb:27017`。
- **Mongo Express の Basic 認証**: ブラウザで開くと最初に `admin`/`admin`（既定）を聞かれる。
- **スキーマレスの罠**: 柔軟な反面、フィールド名の typo がそのまま別フィールドになる。アプリ側でバリデーションを。

## 9. 参考リンク

- 公式ドキュメント: https://www.mongodb.com/docs/
- Docker イメージ: https://hub.docker.com/_/mongo
