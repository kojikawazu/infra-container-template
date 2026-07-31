# infra-container-template

コンテナベースのインフラ構築テンプレート

## Rules

明示的な指示がなくても、`.claude/rules/` 内のルールを常に守ってください。

| ファイル | スコープ | 内容 |
|---------|---------|------|
| shortcuts.md | 全体 | 指示ショートカット（PR出して、PR承認しました 等） |
| workflow.md | 全体 | 開発フロー（ブランチ運用・テスト必須） |
| quality-gate.md | 全体 | 品質ゲート（セルフレビュー・設計/実装レビュー） |
| documentation.md | 全体 | ドキュメント更新ルール |
| git.md | 全体 | GitHub Flow・ブランチ命名・push 禁止物 |
| testing.md | 全体 | テスト分類・原則 |
| security.md | 全体 | セキュリティ方針（ポート公開範囲・シークレット管理・コンテナ権限） |
| github-issue.md | 全体 | GitHub issue 運用（issue とブランチの対応・自動クローズ） |
| codex.md | 全体 | Codex 利用時のエージェント運用ルール |

ルール本文の正本は `.claude/rules/` です。Codex 等の他エージェントは [`AGENTS.md`](AGENTS.md) から同じルールを参照します。ルールファイルを追加・削除・改名した場合は、この表・`AGENTS.md`・README を同一 PR で同期してください。
