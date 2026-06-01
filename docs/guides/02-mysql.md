# MySQL 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `mysql:8.4` |
| コンテナ名 | `infra-mysql` |
| カテゴリ | リレーショナルDB（RDB） |
| profile | `mysql` / `sql` / `all` |
| ホストポート | `3306`（`127.0.0.1` バインド） |
| Web クライアント | Adminer（http://localhost:8080） |

MySQL は世界的に普及した OSS の RDB。Web アプリのバックエンドで広く使われる。本テンプレでは LTS の 8.4 系を採用。

## 2. 目的・ユースケース

- Web アプリ/CMS（WordPress 等）のデータストア検証
- MySQL 方言の SQL 学習・既存スキーマの移行テスト
- MariaDB との挙動比較（[mariadb ガイド](./03-mariadb.md) と同時起動可）

## 3. 起動方法

```bash
docker compose --profile mysql up -d         # MySQL + Adminer
make up p=mysql
docker compose -f databases/mysql/compose.yaml up mysql   # 単独
```

- 関連クライアント: **Adminer** → http://localhost:8080（システム=MySQL、サーバ=`mysql`）
- 初期化: `databases/mysql/initdb/` の `*.sql` / `*.sh` は **初回起動時のみ** 自動実行。

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `3306` |
| コンテナ間 | `mysql` | `3306` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MYSQL_ROOT_PASSWORD` | `rootpass` | root パスワード |
| `MYSQL_DATABASE` | `appdb` | 初期DB名 |
| `MYSQL_USER` | `appuser` | 一般ユーザー |
| `MYSQL_PASSWORD` | `apppass` | 一般ユーザーのパスワード |
| `MYSQL_PORT` | `3306` | ホスト公開ポート |

- データは `infra-mysql-data` に永続化。

## 5. 使用例（CLI）

```bash
docker exec -it infra-mysql mysql -u appuser -papppass appdb
```

```sql
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL);
INSERT INTO users (name) VALUES ('Alice'), ('Bob');
SELECT * FROM users;
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install mysql2
```

```ts
import mysql from "mysql2/promise";

const conn = await mysql.createConnection({
  host: process.env.DB_HOST ?? "localhost", // コンテナ間は "mysql"
  port: 3306,
  user: "appuser",
  password: "apppass",
  database: "appdb",
});

await conn.execute(
  "CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100))"
);
await conn.execute("INSERT INTO users (name) VALUES (?)", ["Alice"]);
const [rows] = await conn.query("SELECT id, name FROM users");
console.log(rows);
await conn.end();
```

## 7. アプリへの実装（Python）

```bash
pip install "mysql-connector-python"
```

```python
import mysql.connector

conn = mysql.connector.connect(
    host="localhost", port=3306,        # コンテナ間は host="mysql"
    user="appuser", password="apppass", database="appdb",
)
cur = conn.cursor()
cur.execute("INSERT INTO users (name) VALUES (%s)", ["Alice"])
conn.commit()
cur.execute("SELECT id, name FROM users")
print(cur.fetchall())
conn.close()
```

## 8. つまずきポイント・Tips

- **`localhost` と `mysql` の取り違え**: ホストのアプリは `localhost:3306`、コンテナ内は `mysql:3306`。
- **root と一般ユーザー**: アプリからは `appuser` を使う。`root` は管理用。
- **initdb は初回のみ**: スキーマ変更時は `docker compose down -v` でボリュームを消して再作成。
- **3307 は MariaDB**: 同居している MariaDB はホスト側 3307。混同しないこと。

## 9. 参考リンク

- 公式ドキュメント: https://dev.mysql.com/doc/
- Docker イメージ: https://hub.docker.com/_/mysql
- 関連: [mariadb ガイド](./03-mariadb.md)
