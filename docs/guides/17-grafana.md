# Grafana (可視化ダッシュボード) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `grafana/grafana:latest` |
| コンテナ名 | `infra-grafana` |
| カテゴリ | 監視（可視化・ダッシュボード） |
| profile | `grafana` / `monitoring` / `all` |
| ホストポート | `3000`（`127.0.0.1` バインド） |
| Web クライアント | Grafana 本体（http://localhost:3000） |

Grafana はメトリクス・ログ・トレースを **1画面で可視化** するダッシュボードツール。本テンプレでは可観測性3本柱（[Prometheus](./16-prometheus.md)=メトリクス / [Loki](./18-loki.md)=ログ / [Tempo](./19-tempo.md)=トレース）のデータソースを**起動時に自動登録**する。

## 2. 目的・ユースケース

- メトリクス/ログ/トレースの統合ダッシュボード作成
- PromQL / LogQL の結果をグラフで可視化
- アラート通知の設定

## 3. 起動方法

```bash
docker compose --profile grafana up -d       # = --profile monitoring（3本柱がまとめて上がる）
make up p=monitoring
docker compose -f monitoring/grafana/compose.yaml up grafana   # 単独
```

- Web UI → http://localhost:3000（`GRAFANA_USER`/`GRAFANA_PASSWORD` でログイン）

## 4. 接続情報

| 接続元 | エンドポイント |
|--------|----------------|
| ホスト PC（ブラウザ） | `http://localhost:3000` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `GRAFANA_PORT` | `3000` | Web UI ポート |
| `GRAFANA_USER` | `admin` | 管理者ユーザー（`GF_SECURITY_ADMIN_USER`） |
| `GRAFANA_PASSWORD` | `admin` | 管理者パスワード（`GF_SECURITY_ADMIN_PASSWORD`） |

- データソースは `monitoring/grafana/provisioning/datasources/datasource.yml` で自動登録（Prometheus / Loki / Tempo）。コンテナ間のサービス名（`http://prometheus:9090` 等）で接続する。
- データ（ダッシュボード等）は `infra-grafana-data` に永続化。

## 5. 使用例（データソースと探索）

起動後、ログインして以下を試す:

1. **Explore**（左メニュー）→ データソース `Prometheus` を選び `up` を実行 → メトリクスが見える
2. **Explore** → `Loki` を選び `{container="infra-..."}` でログ検索
3. **Dashboards > New** → パネルを追加し PromQL/LogQL でグラフ作成

自動登録されるデータソース（`datasource.yml`）:

```yaml
- name: Prometheus   # url: http://prometheus:9090 （既定データソース）
- name: Loki         # url: http://loki:3100
- name: Tempo        # url: http://tempo:3200
```

> Loki/Tempo を `monitoring` profile で起動していない場合、そのデータソースは接続エラーになるだけで害はない。

## 6. データソースの追加・カスタム（プロビジョニング）

新しいデータソースを足したい場合は、`datasource.yml` に追記してコンテナを再起動する（コードで管理＝再現性が高い）:

```yaml
apiVersion: 1
datasources:
  - name: MyPostgres
    type: postgres
    url: postgres:5432       # infra-net 上のサービス名
    user: appuser
    jsonData: { database: appdb, sslmode: disable }
    secureJsonData: { password: apppass }
```

## 7. ダッシュボードの永続化

- GUI で作ったダッシュボードは `infra-grafana-data` に保存され、再起動後も残る。
- チームで共有・バージョン管理したい場合は、ダッシュボードを JSON でエクスポートし `provisioning/dashboards/` で配布する方式が定石（本テンプレは未設定＝任意で追加）。

## 8. つまずきポイント・Tips

- **データソースの URL はサービス名**: Grafana はコンテナなので `http://prometheus:9090`。`localhost` ではない。
- **初回ログイン**: `.env` の `admin`/`admin`。本番では必ず変更する。
- **3本柱は揃えて起動**: `--profile monitoring` で Prometheus/Loki/Tempo/Grafana が一括で上がる。個別起動だと参照先が無く空表示になる。

## 9. 参考リンク

- 公式ドキュメント: https://grafana.com/docs/grafana/latest/
- 関連: [prometheus](./16-prometheus.md) / [loki](./18-loki.md) / [tempo](./19-tempo.md)
