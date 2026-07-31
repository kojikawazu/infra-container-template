# MSSQL (Microsoft SQL Server) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `mcr.microsoft.com/mssql/server:2022-CU26-ubuntu-22.04` |
| コンテナ名 | `infra-mssql` |
| カテゴリ | リレーショナルDB（RDB） |
| profile | `mssql` / `sql` / `all` |
| ホストポート | `1433`（`127.0.0.1` バインド） |
| Web クライアント | Adminer（http://localhost:8080） |

Microsoft SQL Server は、エンタープライズ向けの商用 RDB。T-SQL・ストアドプロシージャ・ウィンドウ関数などが充実。本テンプレでは無償の Developer エディション（`MSSQL_PID=Developer`）で動かす。

## 2. 目的・ユースケース

- .NET / 企業システムで SQL Server を前提とするアプリの検証
- T-SQL の学習、既存 SQL Server スキーマの移行テスト
- 商用 RDB 特有機能（ストアドプロシージャ・トリガー）の動作確認

## 3. 起動方法

```bash
docker compose --profile mssql up -d        # MSSQL + Adminer
make up p=mssql
docker compose -f databases/mssql/compose.yaml up mssql   # 単独
```

- 関連クライアント: **Adminer** → http://localhost:8080（システム=MS SQL、サーバ=`mssql`、ユーザ=`sa`）

## 4. 接続情報

| 接続元 | ホスト | ポート |
|--------|--------|--------|
| ホスト PC | `localhost` | `1433` |
| コンテナ間 | `mssql` | `1433` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MSSQL_SA_PASSWORD` | `Your_strong_Pass123` | `sa` ユーザーのパスワード |
| `MSSQL_PID` | `Developer` | エディション |
| `MSSQL_PORT` | `1433` | ホスト公開ポート |

- 管理者ユーザーは `sa`。データは `infra-mssql-data` に永続化。
- ⚠ **パスワードポリシー**: SA パスワードは「8文字以上＋大文字/小文字/数字/記号のうち3種以上」が必須。これを満たさないとコンテナが起動直後に落ちる。

## 5. 使用例（CLI / sqlcmd）

```bash
# コンテナ内の sqlcmd で接続（イメージ内のツールは mssql-tools18、-C で証明書を信頼）
docker exec -it infra-mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "Your_strong_Pass123" -C -Q "SELECT @@VERSION"
```

```sql
CREATE DATABASE appdb;
GO
USE appdb;
CREATE TABLE users (id INT IDENTITY PRIMARY KEY, name NVARCHAR(100) NOT NULL);
INSERT INTO users (name) VALUES (N'Alice');
SELECT * FROM users;
GO
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install mssql
```

```ts
import sql from "mssql";

const pool = await sql.connect({
  server: process.env.DB_HOST ?? "localhost", // コンテナ間は "mssql"
  port: 1433,
  user: "sa",
  password: "Your_strong_Pass123",
  database: "appdb",
  options: { trustServerCertificate: true }, // 開発用に自己署名証明書を信頼
});

await pool.query`CREATE TABLE IF NOT EXISTS users (id INT IDENTITY PRIMARY KEY, name NVARCHAR(100))`;
const result = await pool.request().query("SELECT id, name FROM users");
console.log(result.recordset);
await pool.close();
```

## 7. アプリへの実装（Python）

```bash
pip install pymssql
```

```python
import pymssql

# ホストからは server="localhost"、コンテナ間は server="mssql"
conn = pymssql.connect(
    server="localhost", port=1433,
    user="sa", password="Your_strong_Pass123", database="appdb",
)
cur = conn.cursor()
cur.execute("SELECT name FROM users")
print(cur.fetchall())
conn.close()
```

## 8. つまずきポイント・Tips

- **パスワードが弱いと起動失敗**: ログに「Password validation failed」が出たら `.env` の `MSSQL_SA_PASSWORD` を強化する。
- **`localhost` と `mssql` の取り違え**: ホストのアプリは `localhost:1433`、コンテナ内のアプリは `mssql:1433`。
- **証明書エラー**: 2022 イメージは TLS を強制するため、開発では `trustServerCertificate: true`（TS）/ sqlcmd の `-C` で証明書を信頼する。
- **起動に時間**: 初回は SQL Server の初期化に 30 秒前後かかる（healthcheck の `start_period` も 30s）。

## 9. 参考リンク

- 公式ドキュメント: https://learn.microsoft.com/sql/
- Docker イメージ: https://hub.docker.com/r/microsoft/mssql-server
- 関連: [セキュリティ仕様書](../06-security-specification.md)
