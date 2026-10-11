SHELL := /bin/bash
-include .env
export

DC    ?= docker compose
QP    := python3 scripts/qp.py
SCALE ?= 1

.DEFAULT_GOAL := help

help: ## show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN{FS=":.*?## "};{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

## ---------- environment ----------
up: ## start postgres + pgadmin
	@test -f .env || cp .env.example .env
	$(DC) up -d
	@echo "waiting for postgres..."
	@until $(DC) exec -T db pg_isready -U $${POSTGRES_USER:-qp} -d $${POSTGRES_DB:-querypractice} >/dev/null 2>&1; do sleep 1; done
	@echo "db: localhost:$${POSTGRES_PORT:-5433}   pgAdmin: http://localhost:$${PGADMIN_PORT:-5050}"

down: ## stop containers (data kept)
	$(DC) down

nuke: ## stop containers AND delete data volumes
	$(DC) down -v

schema: ## (re)create schema, dropping all objects
	@bash scripts/run_sql_dir.sh db/schema

seed: ## generate dataset (make seed SCALE=5)
	@SCALE=$(SCALE) bash scripts/seed.sh

analyze: ## refresh matviews + planner statistics
	@bash scripts/run_sql_dir.sh db/maintenance

build: up schema seed ## full setup: containers + schema + data

reset: nuke build ## wipe everything and rebuild

psql: ## interactive psql shell
	$(DC) exec db psql -U $${POSTGRES_USER:-qp} -d $${POSTGRES_DB:-querypractice}

stats: ## row counts + table sizes
	@$(DC) exec -T db psql -X -U $${POSTGRES_USER:-qp} -d $${POSTGRES_DB:-querypractice} -f /db/maintenance/90_report_sizes.sql

indexes: ## add the "discover these yourself" perf indexes
	@$(DC) exec -T db psql -X -U $${POSTGRES_USER:-qp} -d $${POSTGRES_DB:-querypractice} -f /db/perf/optional_indexes.sql

## ---------- practice ----------
list: ## list topics (make list T=window)
	@$(QP) list $(T)

show: ## show one task: make show Q=T05-03
	@$(QP) show $(Q)

new: ## scaffold work/<id>.sql: make new Q=T05-03
	@$(QP) new $(Q)

diff: ## grade your answer: make diff Q=T05-03 F=work/T05-03.sql
	@$(QP) diff $(Q) $(F)

answer: ## print reference SQL: make answer Q=T05-03
	@$(QP) answer $(Q)

run: ## run reference SQL: make run Q=T05-03
	@$(QP) run $(Q)

explain: ## EXPLAIN ANALYZE reference SQL: make explain Q=T14-02
	@$(QP) explain $(Q)

check: ## execute every reference solution (make check T=08)
	@$(QP) check $(T)

exercises: ## regenerate exercises/*.md from solution headers
	@$(QP) gen

.PHONY: help up down nuke schema seed analyze build reset psql stats indexes \
        list show new diff answer run explain check exercises
