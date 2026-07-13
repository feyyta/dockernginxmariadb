all:
	mkdir -p /home/ma2t/data/wordpress /home/ma2t/data/mariadb
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down -v --rmi all

fclean: clean
	@sudo rm -rf /home/ma2t/data

re: fclean all

.PHONY: all down clean fclean re
