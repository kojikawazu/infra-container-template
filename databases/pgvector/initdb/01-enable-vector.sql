-- pgvector 拡張を有効化（初回起動時に自動実行）。
-- これでベクトル型 vector(N) と近傍検索演算子(<->, <=>, <#>)が使えるようになる。
CREATE EXTENSION IF NOT EXISTS vector;

-- 動作確認用サンプル（不要なら削除可）:
-- CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
-- INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
-- SELECT id, embedding <-> '[3,1,2]' AS distance FROM items ORDER BY distance LIMIT 5;
