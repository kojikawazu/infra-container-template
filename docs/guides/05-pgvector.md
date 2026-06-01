# pgvector 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `pgvector/pgvector:pg17`（PostgreSQL 17 + vector 拡張） |
| コンテナ名 | `infra-pgvector` |
| カテゴリ | ベクトルDB（RDB 拡張） |
| profile | `pgvector` / `vector` / `all` |
| ホストポート | `5433`（`127.0.0.1` バインド／コンテナ内は 5432） |
| Web クライアント | なし（psql / クライアントライブラリで操作） |

pgvector は PostgreSQL に **ベクトル型 `vector(N)` と近傍検索** を追加する拡張。埋め込み（embedding）を保存し、類似度で検索できる。RAG・レコメンド・類似画像/文書検索に使う。

> 業務用 RDB の [postgres](./01-postgres.md)（5432）とは **別コンテナ・別ポート(5433)・別ボリューム** に分離している。資源と役割を混在させないため。

## 2. 目的・ユースケース

- **RAG**（検索拡張生成）: 文書を埋め込み化して保存し、質問に近い文書を検索
- レコメンド・類似検索（商品・画像・テキスト）
- 近傍検索アルゴリズム（HNSW / IVFFlat インデックス）の学習

## 3. 起動方法

```bash
docker compose --profile pgvector up -d      # = --profile vector でも可
make up p=vector
docker compose -f databases/pgvector/compose.yaml up pgvector   # 単独
```

- 初回起動時に `databases/pgvector/initdb/01-enable-vector.sql` が `CREATE EXTENSION vector` を実行する（手動で有効化する必要はない）。

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `5433` |
| コンテナ間 | `pgvector` | `5432` |

> ⚠ ホストからは **5433**、コンテナ間は **5432**（業務 postgres の 5432 と衝突させないためホスト側だけずらしている）。

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `PGVECTOR_DB` | `vectordb` | DB名 |
| `PGVECTOR_USER` | `vectoruser` | ユーザー |
| `PGVECTOR_PASSWORD` | `vectorpass` | パスワード |
| `PGVECTOR_PORT` | `5433` | ホスト公開ポート |

- データは `infra-pgvector-data` に永続化。

## 5. 使用例（CLI / psql）

```bash
docker exec -it infra-pgvector psql -U vectoruser -d vectordb
```

```sql
-- 3次元ベクトルのテーブル（実際の埋め込みは 1536 次元など）
CREATE TABLE items (id SERIAL PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[1,1,1]');

-- L2距離(<->)が近い順に検索（コサインは <=>、内積は <#>）
SELECT id, embedding FROM items ORDER BY embedding <-> '[1,2,2]' LIMIT 2;

-- 大量データは近似インデックスで高速化
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops);
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install pg pgvector
```

```ts
import { Pool } from "pg";
import pgvector from "pgvector/pg";

const pool = new Pool({
  host: process.env.PGHOST ?? "localhost",
  port: Number(process.env.PGPORT ?? 5433),  // コンテナ間は "pgvector":5432
  user: "vectoruser", password: "vectorpass", database: "vectordb",
});

const client = await pool.connect();
await pgvector.registerType(client); // vector 型の入出力を有効化
await client.query("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, embedding vector(3))");
await client.query("INSERT INTO items (embedding) VALUES ($1)", [pgvector.toSql([1, 2, 3])]);
const { rows } = await client.query(
  "SELECT id FROM items ORDER BY embedding <-> $1 LIMIT 1",
  [pgvector.toSql([1, 2, 2])]
);
console.log(rows);
client.release();
```

## 7. アプリへの実装（Python）

```bash
pip install "psycopg[binary]" pgvector
```

```python
import psycopg
from pgvector.psycopg import register_vector

with psycopg.connect(
    host="localhost", port=5433,    # コンテナ間は host="pgvector", port=5432
    user="vectoruser", password="vectorpass", dbname="vectordb",
) as conn:
    register_vector(conn)  # vector 型を numpy/list に対応付け
    conn.execute("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, embedding vector(3))")
    conn.execute("INSERT INTO items (embedding) VALUES (%s)", ([1, 2, 3],))
    rows = conn.execute(
        "SELECT id FROM items ORDER BY embedding <-> %s LIMIT 1", ([1, 2, 2],)
    ).fetchall()
    print(rows)
    conn.commit()
```

## 8. つまずきポイント・Tips

- **ホスト 5433 / コンテナ 5432**: ホストのアプリは `localhost:5433`、コンテナ内は `pgvector:5432`。業務 postgres(5432) と混同しない。
- **次元数は固定**: `vector(N)` の N は埋め込みモデルの次元と一致させる（OpenAI `text-embedding-3-small` なら 1536）。
- **距離演算子の使い分け**: コサイン類似度なら `<=>`、ユークリッド距離なら `<->`、内積なら `<#>`。埋め込みモデルが想定する距離に合わせる。
- **インデックスは件数が増えてから**: 少量データでは全件スキャンで十分。HNSW/IVFFlat は大規模時に効く。

## 9. 参考リンク

- pgvector: https://github.com/pgvector/pgvector
- 関連: [postgres ガイド](./01-postgres.md) / [データ仕様書](../05-data-specification.md)
