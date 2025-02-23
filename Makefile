.PHONY: up down logs ps

build:
	docker build --no-cache . -t poopyloops:latest

up:
	docker compose -f docker-compose.prod.yml up -d

stop:
	docker compose -f docker-compose.prod.yml stop

logs:
	docker compose -f docker-compose.prod.yml logs -f

ps:
	docker compose -f docker-compose.prod.yml ps
