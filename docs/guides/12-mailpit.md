# Mailpit (メール送信テスト) 学習ガイド

> 一覧に戻る → [docs/guides/00-index.md](./00-index.md)

## 1. 概要

| 項目 | 値 |
|------|----|
| イメージ | `axllent/mailpit:v1.30.6` |
| コンテナ名 | `infra-mailpit` |
| カテゴリ | メール（SMTP 受信トラップ + Web UI） |
| profile | `mailpit` / `all` |
| ホストポート | SMTP `1025` / Web UI `8025`（`127.0.0.1` バインド） |
| Web クライアント | Mailpit Web UI（http://localhost:8025） |

Mailpit は開発用の「メール受信トラップ」。アプリが送った SMTP メールを **実際には外部に送らず** キャプチャし、Web UI で内容（本文・HTML・添付）を確認できる。誤って本物の宛先に送る事故を防ぎつつ、メール送信機能を検証できる。

## 2. 目的・ユースケース

- アプリのメール送信機能（登録確認・パスワードリセット等）の検証
- HTML メールの表示確認
- 本番宛先に誤送信しない安全なテスト環境

## 3. 起動方法

```bash
docker compose --profile mailpit up -d
make up p=mailpit
docker compose -f mail/mailpit/compose.yaml up mailpit   # 単独
```

- 関連クライアント: **Mailpit Web UI** → http://localhost:8025（送信されたメールが一覧表示される）

## 4. 接続情報

| 用途 | 接続元 | ホスト | ポート |
|------|--------|--------|--------|
| メール送信（SMTP） | ホスト PC | `localhost` | `1025` |
| メール送信（SMTP） | コンテナ間 | `mailpit` | `1025` |
| 受信確認（ブラウザ） | ホスト PC | `localhost` | `8025` |

| `.env` キー | 既定値 | 用途 |
|-------------|--------|------|
| `MAILPIT_SMTP_PORT` | `1025` | SMTP 受信ポート |
| `MAILPIT_UI_PORT` | `8025` | Web UI ポート |
| `MAILPIT_MAX_MESSAGES` | `500` | 保持する最大メール数（超過分は古い順に削除） |

- ⚠ **認証なし・TLS なし**の SMTP（開発用）。アプリの SMTP 設定はユーザー/パスワード不要、暗号化なしにする。

## 5. 使用例（CLI / swaks など）

```bash
# swaks があれば SMTP に直接送信できる
swaks --server localhost:1025 --from app@example.com --to user@example.com \
  --header "Subject: Test" --body "Hello from Mailpit"
# → http://localhost:8025 に届く
```

## 6. アプリへの実装（TypeScript / Node.js）

```bash
npm install nodemailer
```

```ts
import nodemailer from "nodemailer";

const transport = nodemailer.createTransport({
  host: process.env.SMTP_HOST ?? "localhost", // コンテナ間は "mailpit"
  port: 1025,
  secure: false, // TLS なし（開発用 Mailpit）
  // auth は不要
});

await transport.sendMail({
  from: "app@example.com",
  to: "user@example.com",
  subject: "ようこそ",
  text: "登録ありがとうございます",
  html: "<b>登録ありがとうございます</b>",
});
// → http://localhost:8025 で確認
```

## 7. アプリへの実装（Python）

```python
import smtplib
from email.message import EmailMessage

msg = EmailMessage()
msg["From"] = "app@example.com"
msg["To"] = "user@example.com"
msg["Subject"] = "ようこそ"
msg.set_content("登録ありがとうございます")

# コンテナ間は host="mailpit"
with smtplib.SMTP("localhost", 1025) as smtp:  # 認証・TLS 不要
    smtp.send_message(msg)
# → http://localhost:8025 で確認
```

## 8. つまずきポイント・Tips

- **認証・TLS を設定しない**: Mailpit は認証なし・平文。`secure: true` や `auth` を設定すると逆に失敗する。
- **`localhost` と `mailpit` の取り違え**: ホストのアプリは `localhost:1025`、コンテナ内は `mailpit:1025`。
- **メールは外に出ない**: すべて Mailpit が握りつぶす。本番では実 SMTP（SendGrid 等）に切り替える。
- **保持上限**: 既定 500 件を超えると古いメールから消える。

## 9. 参考リンク

- 公式ドキュメント: https://mailpit.axllent.org/docs/
- GitHub: https://github.com/axllent/mailpit
