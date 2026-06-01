# OpenSearch (全文検索) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `opensearchproject/opensearch:2.17.1`（Apache-2.0） |
| コンテナ名 | `infra-opensearch` |
| カテゴリ | 全文検索エンジン（Elasticsearch 互換） |
| profile | `opensearch` / `search` / `all` |
| ホストポート | `9200`（`127.0.0.1` バインド） |
| Web クライアント | OpenSearch Dashboards（http://localhost:5601） |

OpenSearch は Elasticsearch から派生した OSS の全文検索・分析エンジン。文書を「インデックス」に格納し、形態素解析・スコアリング付きの検索・集計（アグリゲーション）ができる。ログ分析・サイト内検索に使う。API は Elasticsearch 互換。

## 2. 目的・ユースケース

- サイト内/アプリ内の全文検索（あいまい検索・関連度順）
- ログ・メトリクスの集約と可視化（Dashboards）
- 集計分析（ファセット・時系列集計）

## 3. 起動方法

```bash
docker compose --profile opensearch up -d    # = --profile search（Dashboards も上がる）
make up p=search
docker compose -f search/opensearch/compose.yaml up opensearch   # 単独
```

- 関連クライアント: **OpenSearch Dashboards** → http://localhost:5601（`http://opensearch:9200` に自動接続。Dev Tools でクエリ実行可）

## 4. 接続情報

| 接続元 | エンドポイント |
|--------|----------------|
| ホスト PC | `http://localhost:9200` |
| コンテナ間 | `http://opensearch:9200` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `OPENSEARCH_PORT` | `9200` | API ポート |
| `OPENSEARCH_DASHBOARDS_PORT` | `5601` | Dashboards ポート |
| `OPENSEARCH_JAVA_OPTS` | `-Xms512m -Xmx512m` | JVM ヒープ |

- データは `infra-opensearch-data` に永続化。
- ⚠ 開発容易性のため **セキュリティプラグインを無効化（HTTP・認証なし）**。`https`/認証は不要。本番では必ず TLS + 認証を有効化する（[docs/06](../06-security-specification.md)）。

## 5. 使用例（CLI / curl）

```bash
curl localhost:9200                          # クラスタ情報
curl localhost:9200/_cat/indices?v           # インデックス一覧

# 文書を投入（インデックスは自動作成される）
curl -X POST localhost:9200/articles/_doc -H 'Content-Type: application/json' \
  -d '{"title":"OpenSearch入門","tags":["search"]}'

# 検索
curl localhost:9200/articles/_search -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"title":"入門"}}}'
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install @opensearch-project/opensearch
```

```ts
import { Client } from "@opensearch-project/opensearch";

const client = new Client({
  node: process.env.OPENSEARCH_NODE ?? "http://localhost:9200", // コンテナ間は http://opensearch:9200
});

await client.index({
  index: "articles",
  body: { title: "OpenSearch入門", tags: ["search"] },
  refresh: true, // すぐ検索可能にする（開発用）
});

const result = await client.search({
  index: "articles",
  body: { query: { match: { title: "入門" } } },
});
console.log(result.body.hits.hits);
```

## 7. アプリへの実装（Python）

```bash
pip install opensearch-py
```

```python
from opensearchpy import OpenSearch

client = OpenSearch(hosts=[{"host": "localhost", "port": 9200}])  # コンテナ間は host="opensearch"

client.index(index="articles", body={"title": "OpenSearch入門", "tags": ["search"]}, refresh=True)
res = client.search(index="articles", body={"query": {"match": {"title": "入門"}}})
print(res["hits"]["hits"])
```

## 8. つまずきポイント・Tips

- **http で繋ぐ（https ではない）**: セキュリティ無効化のため `http://` + 認証なし。`https`/`admin` パスワードを設定すると逆に失敗する。
- **`localhost` と `opensearch` の取り違え**: ホストのアプリは `localhost:9200`、コンテナ内（Dashboards 含む）は `opensearch:9200`。
- **メモリ不足で起動失敗**: JVM ヒープが足りないと落ちる。Docker のメモリ割り当てを増やすか `OPENSEARCH_JAVA_OPTS` を調整。
- **`refresh` のタイミング**: 投入直後は検索に反映されないことがある。開発では `refresh: true` で即時反映。
- **日本語検索**: 標準アナライザは日本語に弱い。本格運用は `kuromoji` プラグイン等を検討。

## 9. 参考リンク

- 公式ドキュメント: https://opensearch.org/docs/latest/
- 関連: [セキュリティ仕様書](../06-security-specification.md)
