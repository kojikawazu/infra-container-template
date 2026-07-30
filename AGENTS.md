# Codex instructions

このリポジトリは、コンテナベースのインフラ構築テンプレートです。

`.claude/rules/` が開発ルールの唯一の正本です。作業を始める前に次のルールを読み、守ってください。ルール本文をこのファイルへ複製しないでください。

## 常に適用するルール

| ファイル | 内容 |
|---------|------|
| [`.claude/rules/workflow.md`](.claude/rules/workflow.md) | 開発フロー（ブランチ運用・テスト必須） |
| [`.claude/rules/quality-gate.md`](.claude/rules/quality-gate.md) | 品質ゲート（セルフレビュー・設計/実装レビュー） |
| [`.claude/rules/documentation.md`](.claude/rules/documentation.md) | ドキュメント更新ルール（影響マップ） |
| [`.claude/rules/git.md`](.claude/rules/git.md) | GitHub Flow・ブランチ命名・push 禁止物 |
| [`.claude/rules/testing.md`](.claude/rules/testing.md) | テスト分類・原則 |
| [`.claude/rules/shortcuts.md`](.claude/rules/shortcuts.md) | 指示ショートカット |

現時点でパス別（ディレクトリ限定）のルールはありません。すべてのルールがリポジトリ全体に適用されます。

## このリポジトリ固有の注意

- サービス定義は `<カテゴリ>/<名前>/compose.yaml` に独立記述し、ルートの `compose.yaml` が `include` で束ねる。定義を二重管理しない。
- ホストポートは `127.0.0.1` バインドを維持する（[docs/06-security-specification.md](docs/06-security-specification.md)）。
- 構成を変更したら `bash scripts/validate-compose.sh` で検証する。
- 認証情報は `.env` に置き、`.env.example` のみをコミットする。実際のシークレット・鍵ファイルを push しない。

## ルール構成を変更するとき

`.claude/rules/` の本文が唯一の正本です。ルールファイルの追加・削除・改名・適用範囲変更時は、同一変更で [`CLAUDE.md`](CLAUDE.md)、この `AGENTS.md`、README の「AI エージェント向けルール」節を同期してください。ルール本文だけの変更では、これらの入口ファイルを更新する必要はありません。

## ショートカットの扱い

`.claude/rules/shortcuts.md` の意図は守る。ただし Claude 固有のスキル名は、利用可能な Codex の機能・指示に読み替える。Codex は PR の承認・マージを実行しない。
