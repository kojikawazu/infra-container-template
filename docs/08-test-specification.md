# 08. テスト仕様書

テスト戦略・テストケース・カバレッジ目標・ツールを定義する。

## テスト戦略

本テンプレはアプリコードを持たないインフラ定義集のため、**「テスト」= compose 構成の妥当性検証**と位置づける。
`docker compose config` による静的検証で、Docker デーモンを起動せずに「定義が正しくマージ・解決でき、各 profile が意図通りにサービスを選択できる」ことを証明する。実行: `./scripts/validate-compose.sh`。

## テストケース

`scripts/validate-compose.sh` が以下を検証する（詳細な分類は docs/test-design/ 追加時に整理）。

| 分類 | ケース |
|------|--------|
| 正常系 | 全 compose が `--profile all` でマージ・解決できる |
| 正常系 | 各 profile が期待サービス数を選択する（postgres=2, sql=5, monitoring=4, search=2, all=25 等） |
| 正常系 | 新規サービス（pgvector / mailpit / loki / tempo / opensearch / opensearch-dashboards）が正しい profile に含まれる |
| 準正常系 | profile 未指定では 0 サービス（意図的な選択を強制する仕様の証明） |
| 異常系 | 未知の profile を指定しても 0 サービス（安全に空集合を返す） |

> 比率の目安（正常系1 : 異常系2）は業務ロジック向けの指針。構成検証では意味のある異常系が限られるため、network/volume の存在確認など正常系が主となる。

## カバレッジ目標

- ルート `compose.yaml` が `include` する全 compose ファイルが `config` で解決できること（100%）。
- 公開している全 profile が 1 件以上のサービスを解決できること。

## テストツール / 実行環境

- Docker Compose v2.20+（`config --services`）。Bash スクリプト。Docker デーモン不要。
- CI 連携時は `./scripts/validate-compose.sh` を実行（終了コードで合否判定）。
