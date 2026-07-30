---
description: ドキュメント更新・設計書管理ルール（影響マップ + opt-out の完了条件）
globs: 
---

# ドキュメント

コード変更がドキュメント（CLAUDE.md / README.md / docs/）と乖離しないことを構造的に担保する。

## 完了条件（opt-out）

変更は、下記「影響マップ」の対応ドキュメントを**同一 PR 内で更新する**ことを完了条件とする。

- 更新不要と判断した場合は、**PR 説明にその理由を明記する**（省略＝未対応とみなす）。
- この乖離チェックは `/self-review` と `/pr-create` の確認対象に含まれる。

## 影響マップ（変更種別 → 更新必須ドキュメント）

「どのドキュメントだっけ？」を考えさせないための逆引き表。

| 変更種別 | 更新必須ドキュメント |
|---|---|
| サービス追加・削除（compose.yaml / 各サービスの compose.yaml） | README.md（サービス一覧・起動手順）/ docs/09-architecture-specification.md / docs/guides/（該当サービスのガイド追加・削除）/ docs/guides/00-index.md |
| 環境変数の追加・変更・削除 | .env.example / README.md（環境変数の説明）/ docs/06-security-specification.md（機密値の場合） |
| Makefile のターゲット追加・変更（起動・停止・検証コマンド等） | README.md（コマンド一覧・使い方） |
| サービス設定ファイルの変更（prometheus.yml / datasource.yml / tempo.yaml / loki 設定 等） | docs/guides/（該当サービスのガイド）/ docs/09-architecture-specification.md（構成に影響する場合） |
| scripts/ の追加・変更（validate-compose.sh 等） | README.md（実行手順）/ Makefile（呼び出しがある場合） |
| ポート・ボリューム・ネットワーク構成の変更 | README.md（接続情報）/ docs/09-architecture-specification.md / docs/05-data-specification.md（永続化に関わる場合） |
| ディレクトリ構成の変更（サービスカテゴリの追加・移動等） | README.md / CLAUDE.md（構成説明）/ docs/09-architecture-specification.md |
| 機能要件・非機能要件・セキュリティ方針の変更 | docs/01〜11-*.md（該当する仕様書）|
| テスト方針・検証手順の変更 | docs/08-test-specification.md / docs/test-design/（存在する場合） |
| 規約本文の変更（`.claude/rules/`） | 原則不要（正本のルールファイルのみ） |
| 規約ファイルの追加・削除・改名・適用範囲変更 | CLAUDE.md / AGENTS.md / README.md（AI エージェント向けルール節） |

該当する変更がない場合はスキップする。

## 補足

- **設計書の管理**: タスクごとに設計書を新規作成しない。既存の仕様書ドキュメント（docs/01〜11-*.md, docs/test-design/）に追記・更新する。サービス単位のガイドは docs/guides/ に集約する。
- **AI エージェント向け入口の同期**: `.claude/rules/` はルール本文の唯一の正本とする。規約ファイルの構成・名称・適用対象を変更した場合は、Claude Code 向けの `CLAUDE.md`、Codex 向けの `AGENTS.md`、README の対応表を同一 PR で同期する。本文だけの変更では、各入口の更新は不要。
