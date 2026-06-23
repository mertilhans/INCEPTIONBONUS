CYAN    = \033[1;36m
GREEN   = \033[1;32m
RED     = \033[1;31m
YELLOW  = \033[1;33m
RESET   = \033[0m

WP_DATA         = /home/merilhan/data/wordpress
DB_DATA         = /home/merilhan/data/mariadb
PORTAINER_DATA  = /home/merilhan/data/portainer
COMPOSE         = srcs/docker-compose.yml

all:
	@echo "$(CYAN)=== [ MERILHAN | Inception ] ===$(RESET)"
	@mkdir -p $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)
	@docker-compose -f $(COMPOSE) up -d --build
	@echo "$(GREEN)=== [ Done ] ===$(RESET)"
clean:
	@echo "$(YELLOW)🛑 Putting containers to sleep...$(RESET)"
	@docker-compose -f $(COMPOSE) down -v
	@echo "$(GREEN)🧹 Containers stopped successfully.$(RESET)"

fclean: clean
	@echo "$(RED)=== [ Wiping all data ] ===$(RESET)"
	@sudo rm -rf $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)
	@docker system prune -af

re: fclean all

.PHONY: all clean fclean re