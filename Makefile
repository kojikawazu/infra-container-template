# 練習/検証でよく使う操作のショートカット。
# 例: make up p=postgres   /   make down   /   make logs p=sql   /   make ps
.DEFAULT_GOAL := help
p ?= all

.PHONY: help up down stop restart logs ps clean

help: ## このヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## 起動 (例: make up p=postgres / p=sql / p=nosql / p=all)
	docker compose --profile $(p) up -d

down: ## 停止＆コンテナ削除（ボリュームは残す）
	docker compose --profile all down

stop: ## 停止のみ（削除しない）
	docker compose --profile all stop

restart: ## 再起動 (例: make restart p=redis)
	docker compose --profile $(p) restart

logs: ## ログ追従 (例: make logs p=mysql)
	docker compose --profile $(p) logs -f

ps: ## 起動中コンテナ一覧
	docker compose --profile all ps

clean: ## コンテナ＋ボリュームを完全削除（データ消去・注意）
	docker compose --profile all down -v
