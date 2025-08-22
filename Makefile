DC = docker compose -f srcs/docker-compose.yml

all: up
build:
	$(DC) build --no-cache
up:
	$(DC) up -d
down:
	$(DC) down
prepare:
	mkdir -p data/mariadb data/wordpress
	mkdir -p secrets
	[ -f secrets/db_root_password.txt ] || echo "rootpass" > secrets/db_root_password.txt
	[ -f secrets/db_password.txt ] || echo "userpass" > secrets/db_password.txt
clean:
	$(DC) down -v
fclean: clean
	docker image prune -fa
re: fclean all
