#!/usr/bin/env bash
# compose 構成の検証テスト（Docker デーモン不要・`docker compose config` のみで完結）。
# インフラテンプレの「テスト」= 構成定義が正しくマージ・解決でき、各 profile が意図通りに
# サービスを選択できることの証明。CI でもローカルでも実行可能。
#
#   使い方: ./scripts/validate-compose.sh
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0
fail=0
check() { # check <説明> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf "  \033[32mPASS\033[0m %s (=%s)\n" "$1" "$3"; pass=$((pass + 1))
  else
    printf "  \033[31mFAIL\033[0m %s (expected=%s actual=%s)\n" "$1" "$2" "$3"; fail=$((fail + 1))
  fi
}
svc_count() { docker compose --profile "$1" config --services 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' '; }
has_svc() { docker compose --profile "$1" config --services 2>/dev/null | grep -qx "$2" && echo yes || echo no; }

echo "== 正常系: 全 compose がマージ・解決できる =="
if docker compose --profile all config >/dev/null 2>&1; then
  printf "  \033[32mPASS\033[0m docker compose --profile all config\n"; pass=$((pass + 1))
else
  printf "  \033[31mFAIL\033[0m docker compose --profile all config\n"; fail=$((fail + 1))
fi

echo "== 正常系: 各 profile が期待サービス数を選択する =="
check "profile=postgres"   2  "$(svc_count postgres)"
check "profile=sql"        5  "$(svc_count sql)"
check "profile=nosql"      4  "$(svc_count nosql)"
check "profile=storage"    1  "$(svc_count storage)"
check "profile=messaging"  3  "$(svc_count messaging)"
check "profile=emulator"   2  "$(svc_count emulator)"
check "profile=monitoring" 4  "$(svc_count monitoring)"
check "profile=search"     2  "$(svc_count search)"
check "profile=vector"     1  "$(svc_count vector)"
check "profile=mailpit"    1  "$(svc_count mailpit)"
check "profile=all"        25 "$(svc_count all)"

echo "== 正常系: 新規サービスが正しい profile に含まれる =="
check "pgvector in vector"               yes "$(has_svc vector pgvector)"
check "mailpit in mailpit"               yes "$(has_svc mailpit mailpit)"
check "loki in monitoring"               yes "$(has_svc monitoring loki)"
check "tempo in monitoring"              yes "$(has_svc monitoring tempo)"
check "opensearch in search"             yes "$(has_svc search opensearch)"
check "opensearch-dashboards in search"  yes "$(has_svc search opensearch-dashboards)"

echo "== 準正常系: profile 未指定では何も起動しない（意図的な選択を強制）=="
check "no profile -> 0 services" 0 "$(docker compose config --services 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')"

echo "== 異常系: 未知の profile は 0 サービス（安全に空集合）=="
check "unknown profile -> 0 services" 0 "$(svc_count no-such-profile)"

echo
echo "結果: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
