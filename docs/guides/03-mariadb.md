# MariaDB 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `mariadb:11.4` |
| コンテナ名 | `infra-mariadb` |
| カテゴリ | リレーショナルDB（RDB） |
| profile | `mariadb` / `sql` / `all` |
| ホストポート | `3307`（`127.0.0.1` バインド／コンテナ内は 3306） |
| Web クライアント | Adminer（http://localhost:8080） |

MariaDB は MySQL から派生した OSS の RDB。MySQL 互換のプロトコル・SQL を持ちつつ、独自のストレージエンジンや機能を追加している。MySQL と同時に動かせるよう、**ホスト側ポートは 3307** にずらしてある。

## 2. 目的・ユースケース

- MySQL 互換環境の検証（MariaDB を採用するサービス向け）
- MySQL との挙動差の比較（両方を同時起動できる）
- OSS で完結する RDB 学習環境

## 3. 起動方法

```bash
docker compose --profile mariadb up -d       # MariaDB + Adminer
make up p=mariadb
docker compose -f databases/mariadb/compose.yaml up mariadb   # 単独
```

- 関連クライアント: **Adminer** → http://localhost:8080（システム=MySQL、サーバ=`mariadb`）
- 初期化: `databases/mariadb/initdb/` の `*.sql` / `*.sh` は **初回起動時のみ** 自動実行。

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `3307` |
| コンテナ間 | `mariadb` | `3306` |

> ⚠ ポートに注意。ホストからは **3307**、コンテナ間は **3306**（MySQL と同居させるためホスト側だけずらしている）。

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MARIADB_ROOT_PASSWORD` | `rootpass` | root パスワード |
| `MARIADB_DATABASE` | `appdb` | 初期DB名 |
| `MARIADB_USER` | `appuser` | 一般ユーザー |
| `MARIADB_PASSWORD` | `apppass` | 一般ユーザーのパスワード |
| `MARIADB_PORT` | `3307` | ホスト公開ポート |

- データは `infra-mariadb-data` に永続化。

## 5. 使用例（CLI）

```bash
docker exec -it infra-mariadb mariadb -u appuser -papppass appdb
```

```sql
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL);
INSERT INTO users (name) VALUES ('Alice');
SELECT * FROM users;
```

## 6. アプリへの実装（TypeScript / Node.js）

MySQL 互換なので `mysql2` がそのまま使える。**ホストから繋ぐときはポート 3307** に注意。

```bash
npm install mysql2
```

```ts
import mysql from "mysql2/promise";

const conn = await mysql.createConnection({
  host: process.env.DB_HOST ?? "localhost",
  port: Number(process.env.DB_PORT ?? 3307), // コンテナ間は host="mariadb", port=3306
  user: "appuser",
  password: "apppass",
  database: "appdb",
});
const [rows] = await conn.query("SELECT 1 AS ok");
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
    host="localhost", port=3307,        # コンテナ間は host="mariadb", port=3306
    user="appuser", password="apppass", database="appdb",
)
cur = conn.cursor()
cur.execute("SELECT 1")
print(cur.fetchall())
conn.close()
```

## 8. つまずきポイント・Tips

- **ホスト 3307 / コンテナ 3306**: ホストのアプリは `localhost:3307`、コンテナ内のアプリは `mariadb:3306`。最頻出のミス。
- **MySQL との混同**: クライアント設定でサーバ名を `mariadb` にする（`mysql` だと別コンテナに繋がる）。
- **initdb は初回のみ**: スキーマ変更時は `docker compose down -v`。

## 9. 参考リンク

- 公式ドキュメント: https://mariadb.org/documentation/
- Docker イメージ: https://hub.docker.com/_/mariadb
- 関連: [mysql ガイド](./02-mysql.md)
