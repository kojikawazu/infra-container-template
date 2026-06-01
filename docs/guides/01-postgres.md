# PostgreSQL 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `postgres:17` |
| コンテナ名 | `infra-postgres` |
| カテゴリ | リレーショナルDB（RDB） |
| profile | `postgres` / `sql` / `all` |
| ホストポート | `5432`（`127.0.0.1` バインド） |
| Web クライアント | Adminer（http://localhost:8080） |

PostgreSQL は、堅牢なトランザクション・豊富なデータ型（JSONB・配列・範囲型）・拡張機構を備えたオープンソースの RDB。本テンプレでは業務データ向けの標準 RDB として用意している。

> ベクトル検索（RAG・類似検索）が目的なら、別コンテナの [pgvector](./05-pgvector.md)（ポート 5433）を使う。業務DBと役割を分離している。

## 2. 目的・ユースケース

- Web アプリ/API のメインデータストア（ユーザー・注文などの構造化データ）
- トランザクション整合性が必要な処理（決済・在庫など）
- JSONB を使った半構造化データの格納とインデックス検索
- SQL の学習・検証環境

## 3. 起動方法

```bash
# プロファイル起動（Postgres + Adminer がまとめて上がる）
docker compose --profile postgres up -d
# Makefile ショートカット
make up p=postgres

# 単独起動（Adminer なしで Postgres だけ）
docker compose -f databases/postgres/compose.yaml up postgres
```

- 関連クライアント: **Adminer**（`docker compose --profile postgres up -d` で同時起動）→ http://localhost:8080
  - ログイン画面で「システム=PostgreSQL」「サーバ=`postgres`」「ユーザ/パスワード/DB=`.env` の値」を入力。
- 初期化スクリプト: `databases/postgres/initdb/` に置いた `*.sql` / `*.sh` は **初回起動時のみ** 自動実行される（テーブル作成やシードに使う）。

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC（アプリ/CLI） | `localhost` | `5432` |
| コンテナ間（同一 `infra-net`） | `postgres` | `5432` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `POSTGRES_DB` | `appdb` | 初期データベース名 |
| `POSTGRES_USER` | `appuser` | ユーザー名 |
| `POSTGRES_PASSWORD` | `apppass` | パスワード |
| `POSTGRES_PORT` | `5432` | ホスト公開ポート |

- データは名前付きボリューム `infra-postgres-data` に永続化される（`down` では消えない／`down -v` で消える）。
- ⚠ パスワードは開発用ダミー。LAN/公開環境で使う場合は必ず `.env` を変更する（[docs/06](../06-security-specification.md)）。

## 5. 使用例（CLI / psql）

```bash
# コンテナ内の psql に入る
docker exec -it infra-postgres psql -U appuser -d appdb

# ワンライナーでクエリ実行
docker exec -it infra-postgres psql -U appuser -d appdb -c "SELECT version();"
```

```sql
-- psql 内での基本操作
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT now());
INSERT INTO users (name) VALUES ('Alice'), ('Bob');
SELECT * FROM users;
\dt          -- テーブル一覧
\q           -- 終了
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install pg
```

```ts
import { Pool } from "pg";

// ホストのアプリから繋ぐ場合は localhost:5432。
// 同じ infra-net 上のコンテナから繋ぐ場合は host を "postgres" にする。
const pool = new Pool({
  host: process.env.PGHOST ?? "localhost",
  port: Number(process.env.PGPORT ?? 5432),
  user: "appuser",
  password: "apppass",
  database: "appdb",
});

async function main() {
  await pool.query(
    "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)"
  );
  await pool.query("INSERT INTO users (name) VALUES ($1)", ["Alice"]);
  const { rows } = await pool.query("SELECT id, name FROM users");
  console.log(rows); // [{ id: 1, name: 'Alice' }]
  await pool.end();
}

main();
```

## 7. アプリへの実装（Python）

```bash
pip install "psycopg[binary]"
```

```python
import psycopg

# ホストからは host="localhost"、コンテナ間は host="postgres"
with psycopg.connect(
    host="localhost", port=5432,
    user="appuser", password="apppass", dbname="appdb",
) as conn:
    with conn.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)"
        )
        cur.execute("INSERT INTO users (name) VALUES (%s)", ["Alice"])
        cur.execute("SELECT id, name FROM users")
        print(cur.fetchall())  # [(1, 'Alice')]
    conn.commit()
```

## 8. つまずきポイント・Tips

- **`localhost` と `postgres` の取り違え**: ホスト PC で動かすアプリは `localhost:5432`、Docker コンテナ内のアプリは `postgres:5432`。コンテナ間で `localhost` を指定すると「自分自身」を指して接続失敗する。
- **initdb は初回のみ**: `initdb/` のスクリプトはボリュームが空のときだけ実行される。スキーマを変えたら `docker compose down -v` でボリュームを消して再作成するか、マイグレーションで対応する。
- **接続できない（起動直後）**: 初回はDB初期化に十数秒かかる。compose の healthcheck（`pg_isready`）が `healthy` になってから接続する。
- **ポート競合**: ホストで別の Postgres が 5432 を使っていると起動失敗。`.env` の `POSTGRES_PORT` を変更する。

## 9. 参考リンク

- 公式ドキュメント: https://www.postgresql.org/docs/
- Docker イメージ: https://hub.docker.com/_/postgres
- 関連: [pgvector ガイド](./05-pgvector.md) / [データ仕様書](../05-data-specification.md) / [セキュリティ仕様書](../06-security-specification.md)
