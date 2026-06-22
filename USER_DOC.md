# USER_DOC — Inception Project

*User and administrator documentation for the Inception Docker infrastructure.*

---

## 1. What Services Are Provided

This project runs 8 services together inside Docker containers. They all work on one machine and communicate through a private Docker network.

| Service | Description | Access |
|---|---|---|
| NGINX | Main entry point. Handles HTTPS for all services. | Port 443 |
| WordPress | The main website with PHP-FPM. | `https://merilhan.42.fr` |
| MariaDB | Database for WordPress. Not reachable from outside. | Internal only |
| Redis | Memory cache for WordPress. Makes the site faster. | Internal only |
| FTP Server | File access to WordPress files via FTP protocol. | Port 21 |
| Static Site | Personal portfolio website (HTML/CSS/JS). | `/portfolio/` |
| Adminer | Browser interface to view and manage the database. | `/adminer/` |
| Portainer | Browser interface to manage Docker containers. | `/portainer/` |

Only NGINX (port 443) and FTP (port 21) are open to the outside. Everything else is hidden inside the Docker network.

---

## 2. Start and Stop the Project

### Before First Start

**Step 1 — Add the domain to your hosts file:**
```bash
echo "127.0.0.1 merilhan.42.fr" | sudo tee -a /etc/hosts
```

**Step 2 — Create the secrets folder with password files:**
```bash
mkdir -p secrets
echo "your_db_password"       > secrets/db_password.txt
echo "your_root_password"     > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password"  > secrets/wp_user_password.txt
echo "your_ftp_password"      > secrets/ftp_password.txt
```

**Step 3 — Create `srcs/.env`:**
```env
DOMAIN_NAME=merilhan.42.fr
DB_NAME=wordpress_db
DB_USER=wp_manager
WP_TITTLE=Inception_merilhan
WP_ADMIN_USER=mert1337
WP_ADMIN_EMAIL=merilhan@student.42kocaeli.com.tr
WP_USER=user59
WP_USER_EMAIL=merilhanbv@gmail.com
FTP_USER=ftpuser
```

### Start

```bash
make
```

Builds all Docker images and starts all 8 containers. First start takes a few minutes. WordPress installs itself automatically — just wait.

### Stop

```bash
make clean
```

Stops and removes all containers and volumes. Data folders on disk are kept safe.

### Full Reset

```bash
make fclean
```

Removes everything: containers, images, volumes, and data folders. Use this when you want to start from zero.

### Rebuild After Changes

```bash
make re
```

Runs `fclean` then `make`. Use this after changing a Dockerfile or config file.

---

## 3. Access the Website and Administration Panel

Open your browser and go to one of these addresses:

| What | URL |
|---|---|
| WordPress site | `https://merilhan.42.fr` |
| WordPress admin panel | `https://merilhan.42.fr/wp-admin` |
| Portfolio | `https://merilhan.42.fr/portfolio/` |
| Database manager | `https://merilhan.42.fr/adminer/` |
| Container manager | `https://merilhan.42.fr/portainer/` |

> **Browser security warning:** The SSL certificate is self-signed. This is normal for a local project. Click **Advanced** → **Accept** (or **Proceed**) to continue.

**FTP access:**
- Host: `merilhan.42.fr`
- Port: `21`
- Mode: Passive

---

## 4. Locate and Manage Credentials

All passwords are stored in the `secrets/` folder at the root of the project. This folder is not in git.

| File | Used for |
|---|---|
| `secrets/db_password.txt` | WordPress database user password |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/wp_admin_password.txt` | WordPress admin login |
| `secrets/wp_user_password.txt` | WordPress regular user login |
| `secrets/ftp_password.txt` | FTP server login |

### WordPress Admin Login
- URL: `https://merilhan.42.fr/wp-admin`
- Username: `mert1337`
- Password: content of `secrets/wp_admin_password.txt`

### WordPress User Login
- Username: `user59`
- Password: content of `secrets/wp_user_password.txt`

### Adminer Login
- URL: `https://merilhan.42.fr/adminer/`
- Server: `mariadb`
- Username: `wp_manager`
- Password: content of `secrets/db_password.txt`
- Database: `wordpress_db`

### Portainer
- URL: `https://merilhan.42.fr/portainer/`
- On first start, Portainer asks you to create an admin account. You have 5 minutes to do this.
- If you see a timeout page, run:
```bash
docker restart $(docker ps -q -f name=portainer)
```
Then quickly go to the URL and create the account.

---

## 5. Check That Services Are Running

### See all containers

```bash
docker ps
```

You should see 8 containers, all with status `Up`. Example:

```
CONTAINER ID   IMAGE       STATUS        PORTS
...            nginx       Up 2 hours    0.0.0.0:443->443/tcp
...            wordpress   Up 2 hours
...            mariadb     Up 2 hours
...            redis       Up 2 hours
...            ftp         Up 2 hours    0.0.0.0:21->21/tcp
...            static      Up 2 hours
...            adminer     Up 2 hours
...            portainer   Up 2 hours
```

### Read logs of a container

```bash
docker logs <container_name>
```

Examples:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Common problems and solutions

| Problem | What to check |
|---|---|
| "Site can't be reached" | Did you add `merilhan.42.fr` to `/etc/hosts`? |
| WordPress 502 error | WordPress may still be installing. Wait 1–2 minutes. |
| WordPress white page | Run `docker logs wordpress` to see errors. |
| Portainer timeout | Restart: `docker restart $(docker ps -q -f name=portainer)` |
| FTP connection refused | Check port 21 is not blocked by firewall. Use passive mode. |
| Container keeps restarting | Run `docker logs <name>` to find the error. |

---

*Project by merilhan — 42 Kocaeli*
