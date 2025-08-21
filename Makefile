DC = docker compose -f srcs/docker-compose.yml

all: up
build:
	$(DC) build --no-cache
up:
	$(DC) up -d
down:
	$(DC) down
clean:
	$(DC) down -v
fclean: clean
	docker image prune -fa
re: fclean all
