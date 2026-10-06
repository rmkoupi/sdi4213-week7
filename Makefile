# Week 7 individual exercise — one entry point for every milestone command.
#
# Lives in the root of the week 7 repo. Targets are in milestone order;
# `make help` lists them.
#
#   make test      # M1  pytest in the venv
#   make local     # M1  Streamlit on SQLite            -> screenshot 1
#   make env       # M2  .env from .env.example, confirm it is git-ignored
#   make up ps     # M5  build + start the stack         -> screenshot 2
#   make restart   # M8  down / up, volume kept          -> screenshot 5
#   make logs      # M9  web-service logs                -> screenshot 6
#   make nuke CONFIRM=yes   # M10  down -v / up          -> screenshot 7

PY       ?= 3.13
VENV     := .venv
BIN      := $(VENV)/bin
COMPOSE  ?= docker compose
# Optional: terminal renderer from the programme repo, for `make shots`.
TERMSHOT ?= $(HOME)/dev/oupidevops/scripts/termshot/render.py
SHOTS    ?= docs/screenshots

.PHONY: help venv test local env config up ps logs logs-db down restart nuke psql shots clean

help: ## list targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

# ---- Milestone 1: the starter works locally (SQLite) -----------------------

# uv fetches Python 3.13 itself (the system python3 here is 3.14).
$(BIN)/python:
	uv venv --python $(PY) $(VENV)
	uv pip install -q --python $(BIN)/python -r requirements.txt

venv: $(BIN)/python ## create .venv and install requirements

test: venv ## run the automated tests (same invocation as the handout)
	$(BIN)/python -m pytest -v

local: venv ## run Streamlit locally on SQLite, http://localhost:8501
	$(BIN)/streamlit run app/main.py

# ---- Milestone 2: environment configuration --------------------------------

.env:
	cp .env.example .env
	@echo ">> .env created. Edit POSTGRES_PASSWORD before 'make up'."

env: .env ## create .env if missing and prove git ignores it
	@git check-ignore -v .env || { echo ".env is NOT ignored"; exit 1; }
	@! grep -q '^POSTGRES_PASSWORD=change-me$$' .env \
	  || { echo "POSTGRES_PASSWORD is still the placeholder"; exit 1; }

# ---- Milestones 3-5: the Compose stack -------------------------------------

config: env ## validate compose.yaml and list the services it defines
	$(COMPOSE) config --quiet && $(COMPOSE) config --services

up: env ## build and start web + db + adminer in the background
	$(COMPOSE) up --build -d

ps: ## show service state (db should say healthy)
	$(COMPOSE) ps

# ---- Milestones 8-10: persistence, logs, volume removal --------------------

logs: ## web-service logs
	$(COMPOSE) logs web

logs-db: ## database logs
	$(COMPOSE) logs db

down: ## stop and remove containers, KEEP the volume
	$(COMPOSE) down

restart: ## down then up: containers replaced, data survives
	$(COMPOSE) down
	$(COMPOSE) up -d

nuke: ## down -v then up: volume deleted, data gone (needs CONFIRM=yes)
	@test "$(CONFIRM)" = yes \
	  || { echo "Deletes the database volume. Screenshots 3-6 done? Then: make nuke CONFIRM=yes"; exit 1; }
	$(COMPOSE) down -v
	$(COMPOSE) up -d

psql: ## count rows in requests straight from the db container
	$(COMPOSE) exec db sh -c 'psql -U $$POSTGRES_USER -d $$POSTGRES_DB -c "SELECT id, title, status, created_at FROM requests ORDER BY id"'

# ---- Evidence --------------------------------------------------------------

shots: ## render `compose ps` and `compose logs web` to PNG (screenshots 2, 6)
	@test -f "$(TERMSHOT)" || { echo "no renderer at $(TERMSHOT)"; exit 1; }
	@mkdir -p $(SHOTS)
	{ echo "$$ docker compose ps"; $(COMPOSE) ps; } \
	  | /usr/bin/python3 $(TERMSHOT) --out $(SHOTS)/02-compose-ps.png --title "bash — docker compose ps"
	{ echo "$$ docker compose logs web"; $(COMPOSE) logs --no-color web 2>&1 | tail -30; } \
	  | /usr/bin/python3 $(TERMSHOT) --out $(SHOTS)/06-logs-web.png --title "bash — docker compose logs web"

clean: ## remove the venv, caches and the local SQLite file
	rm -rf $(VENV) .pytest_cache helpdesk.db
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
