CYAN    = \033[1;36m
PURPLE  = \033[1;35m
GREEN   = \033[1;32m
RED     = \033[1;31m
YELLOW  = \033[1;33m
RESET   = \033[0m

WP_DATA     = /home/merilhan/data/wordpress
DB_DATA     = /home/merilhan/data/mariadb
COMPOSE     = srcs/docker-compose.yml

all:
	@echo "$(CYAN)🚀 === [ MERILHAN | Firing up the system! ] === 🚀$(RESET)"
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	@echo "$(YELLOW)🐳 Waking up the containers...$(RESET)"
	@docker-compose -f $(COMPOSE) up -d --build
	@echo "$(PURPLE)⏳ Waiting for services to stabilize...$(RESET)"
	@sleep 20
	@echo "$(GREEN)✨ === [ Everything is ready, enjoy! ] === ✨$(RESET)"
clean:
	@echo "$(YELLOW)🛑 Putting containers to sleep...$(RESET)"
	@docker-compose -f $(COMPOSE) down -v
	@echo "$(GREEN)🧹 Containers stopped successfully.$(RESET)"

fclean: clean
	@echo "$(RED)🗑️  Nuking all data and Docker cache...$(RESET)"
	@sudo rm -rf $(WP_DATA)
	@sudo rm -rf $(DB_DATA)
	@docker system prune -af
	@echo "$(RED)💥 All clean! System is wiped out.$(RESET)"

re: fclean all

.PHONY: all clean fclean re