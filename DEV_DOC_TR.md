# Docker Geliştirici Rehberi (Türkçe)

*Bu projeyi anlamak ve çalıştırmak için bilmen gereken her şey.*

---

## İçindekiler

1. [Docker Nedir?](#docker-nedir)
2. [Temel Kavramlar](#temel-kavramlar)
3. [Kurulum](#kurulum)
4. [Docker Komutları](#docker-komutları)
5. [Docker Compose Komutları](#docker-compose-komutları)
6. [Dockerfile — Derinlemesine](#dockerfile--derinlemesine)
7. [Docker Katmanları ve Build Cache](#docker-katmanları-ve-build-cache)
8. [Docker Ağları — Derinlemesine](#docker-ağları--derinlemesine)
9. [Docker Volume'ları — Derinlemesine](#docker-volumeları--derinlemesine)
10. [Docker Secrets — Derinlemesine](#docker-secrets--derinlemesine)
11. [PID 1 ve Sinyal Yönetimi](#pid-1-ve-sinyal-yönetimi)
12. [Bu Projede Kullanılan Servisler](#bu-projede-kullanılan-servisler)
13. [Bir Web İsteği Adım Adım Nasıl Çalışır](#bir-web-isteği-adım-adım-nasıl-çalışır)
14. [SSL ve HTTPS Açıklaması](#ssl-ve-https-açıklaması)
15. [NGINX Konfigürasyonu Açıklaması](#nginx-konfigürasyonu-açıklaması)
16. [PHP-FPM ve FastCGI Açıklaması](#php-fpm-ve-fastcgi-açıklaması)
17. [MariaDB — Faydalı Komutlar](#mariadb--faydalı-komutlar)
18. [Redis — Faydalı Komutlar](#redis--faydalı-komutlar)
19. [WP-CLI — WordPress'i Terminalden Yönetmek](#wp-cli--wordpressi-terminalden-yönetmek)
20. [FTP — Aktif ve Pasif Mod](#ftp--aktif-ve-pasif-mod)
21. [Kullanılan Shell Script Kalıpları](#kullanılan-shell-script-kalıpları)
22. [Ortam Değişkenleri — Nasıl Akar](#ortam-değişkenleri--nasıl-akar)
23. [docker-compose.yml — Satır Satır](#docker-composeyml--satır-satır)
24. [Makefile — Açıklaması](#makefile--açıklaması)
25. [Container Yaşam Döngüsü](#container-yaşam-döngüsü)
26. [Yeniden Başlatma Politikaları](#yeniden-başlatma-politikaları)
27. [depends_on — Sınırlamaları](#depends_on--sınırlamaları)
28. [Health Check (Sağlık Kontrolü)](#health-check-sağlık-kontrolü)
29. [/var/run/docker.sock Nedir](#varrunDockerSock-nedir)
30. [HTTP Durum Kodları — Debug İçin](#http-durum-kodları--debug-için)
31. [Multi-Stage Build](#multi-stage-build)
32. [Container İçinde Faydalı Linux Komutları](#container-içinde-faydalı-linux-komutları)
33. [Bu Proje — Mimari](#bu-proje--mimari)
34. [Portlar ve Servisler](#portlar-ve-servisler)
35. [Veri Depolama](#veri-depolama)
36. [Projeyi Yönetmek](#projeyi-yönetmek)
37. [Güvenlik En İyi Pratikleri](#güvenlik-en-i̇yi-pratikleri)
38. [Sorun Giderme](#sorun-giderme)
39. [Hızlı Başvuru Kartı](#hızlı-başvuru-kartı)

---

## Docker Nedir?

Docker, uygulamaları **container** adı verilen izole kutular içinde çalıştırmana izin veren bir araçtır. Container'ın içinde uygulamanın ihtiyaç duyduğu her şey vardır — kod, kütüphaneler, konfigürasyon. Bu kutu her makinede aynı şekilde çalışır.

### Neden Faydalı?

Bir program yazdığını ve kendi bilgisayarında mükemmel çalıştığını düşün. Sonra arkadaşına gönderiyorsun ve "bende çalışmıyor" diyor. Bu, onun makinesinde farklı yazılım sürümleri, farklı ayarlar veya farklı işletim sistemi olduğu için oluyor.

Docker bu sorunu çözüyor. Uygulamanı ihtiyaç duyduğu her şeyle birlikte bir container'a koyuyorsun. Artık her yerde aynı şekilde çalışıyor — kendi bilgisayarında, arkadaşının bilgisayarında, başka bir ülkedeki sunucuda, her yerde.

### Docker vs Sanal Makine

Sanal makine (VM) tam bir işletim sistemi çalıştırır. Kendi kernel'i, kendi bellek yönetimi, her şey kopyalanmış olur. Ağır ve başlaması yavaştır.

Docker container'ları host makinenin kernel'ini paylaşır. Sadece uygulamayı ve bağımlılıklarını içerir. Hafiftir ve saniyeler içinde başlar.

```
Sanal Makine:
┌─────────────────────────────────────┐
│  Uygulama A  │  Uygulama B         │
│  Kütüphaneler│  Kütüphaneler       │
│  Tam İS      │  Tam İS             │
│  (kernel)    │  (kernel)           │
├──────────────┴──────────────────────┤
│           Hypervisor                │
│           Host İS + Kernel          │
│           Donanım                   │
└─────────────────────────────────────┘

Docker:
┌─────────────────────────────────────┐
│  Uygulama A  │  Uygulama B         │
│  Kütüphaneler│  Kütüphaneler       │
│  (kernel yok)│  (kernel yok)       │
├──────────────┴──────────────────────┤
│           Docker Engine             │
│           Host İS + Kernel (paylaşımlı) │
│           Donanım                   │
└─────────────────────────────────────┘
```

| | Sanal Makine | Docker Container |
|---|---|---|
| Başlangıç süresi | 1-5 dakika | 1 saniyeden az |
| Bellek kullanımı | Her VM için 512MB+ | Container başına 10-50MB |
| İzolasyon | Tam İS izolasyonu | Süreç izolasyonu |
| Disk alanı | VM başına birkaç GB | Genellikle 200MB'den az |
| İdeal kullanım | Maksimum güvenlik | Geliştirme ve mikro servisler |

---

## Temel Kavramlar

### Image (İmaj)

Image salt okunur bir şablondur. Container'ın içinde ne olması gerektiğini tam olarak tanımlar. Image'lar `Dockerfile`'dan oluşturulur. Tarif gibi düşün — tarif değişmez ama ondan istediğin kadar yemek pişirebilirsin.

```
Dockerfile  →  (docker build)  →  Image  →  (docker run)  →  Container
  Tarif                          Plan                     Çalışan örnek
```

Image'lar **katmanlardan** oluşur. Dockerfile'daki her komut bir katman oluşturur. Katmanlar önbelleğe alınır, bu da yeniden oluşturmayı hızlı yapar.

### Container

Container, bir image'ın çalışan örneğidir. İzole edilmiştir — kendi dosya sistemi, kendi ağ arayüzü, kendi süreç alanı vardır. Aynı image'dan birden fazla container, volume kurmadan veri paylaşmaz.

```bash
# Bir image, birden fazla container
docker run -d --name web1 nginx
docker run -d --name web2 nginx
docker run -d --name web3 nginx
# Üç tamamen ayrı container, aynı image
```

### Volume

Container'lar varsayılan olarak geçicidir — container'ı silersen içindeki her şey de gider. Volume'lar, container'ın yaşam döngüsünün dışında yaşayan depolama alanlarıdır. Container'ı silip yeniden oluşturabilirsin ama volume (ve verileri) kalır.

### Ağ (Network)

Docker ağı, container'ların birbirleriyle iletişim kurmasını sağlar. Docker, ağ içinde DNS yönetir — container'lar IP adresi yerine servis adıyla birbirini bulur. IP adresleri değişebilir ama servis adları sabittir.

### Dockerfile

Image oluşturmak için komutları içeren metin dosyası. Her komut image'a bir katman ekler.

### docker-compose.yml

Birden fazla servisi (container), ayarlarını, ağlarını ve volume'larını tanımlayan konfigürasyon dosyası. Uzun `docker run` komutlarını tek tek çalıştırmak yerine, bir compose dosyası yazıp `docker-compose up` diyorsun.

---

## Kurulum

### Debian/Ubuntu'ya Docker Kurulumu

```bash
# Adım 1 — Paket listesini güncelle
sudo apt-get update

# Adım 2 — Gerekli paketleri kur
sudo apt-get install -y ca-certificates curl gnupg

# Adım 3 — Docker'ın resmi GPG anahtarını ekle
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adım 4 — Docker deposunu apt kaynaklarına ekle
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Adım 5 — Docker'ı kur
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Adım 6 — Kurulumu doğrula
docker --version
docker compose version
```

### Docker'ı sudo Olmadan Çalıştırma

Varsayılan olarak sadece root Docker komutlarını çalıştırabilir. Kullanıcını docker grubuna ekle:

```bash
sudo usermod -aG docker $USER
newgrp docker        # değişikliği mevcut terminale uygula
# VEYA çıkış yap ve tekrar giriş yap
```

### Docker'ın Çalıştığını Doğrula

```bash
docker run hello-world
# "Hello from Docker!" yazısını görmeli
```

---

## Docker Komutları

### Image'lar

```bash
# Makinendeki tüm image'ları listele
docker images
docker image ls             # aynı şey

# DockerHub'dan image çek
docker pull debian:bookworm

# Mevcut dizindeki Dockerfile'dan image oluştur
docker build -t uygulamam:latest .

# Belirli bir Dockerfile ile oluştur
docker build -t uygulamam -f path/to/Dockerfile .

# Build argümanı ile oluştur
docker build --build-arg SURUMUM=1.2 -t uygulamam .

# Mevcut image'a yeni bir isim ver
docker tag uygulamam uygulamam:v1.0

# Bir image'ı sil
docker rmi uygulamam:latest

# Kullanılmayan tüm image'ları sil
docker image prune

# TÜM image'ları sil (kullanılanlar dahil) — dikkatli ol
docker image prune -a

# Image'ın nasıl oluşturulduğunu göster (tüm katmanlar)
docker history uygulamam

# Image'ı incele — JSON olarak tüm metadata
docker inspect uygulamam

# Image'ı tar dosyasına kaydet
docker save -o uygulamam.tar uygulamam

# Tar dosyasından image yükle
docker load -i uygulamam.tar
```

### Container'lar

```bash
# Container çalıştır (ana süreç bitince durur)
docker run debian echo "merhaba"

# Arka planda (detached) çalıştır
docker run -d nginx

# Özel isimle çalıştır
docker run -d --name benim-nginx nginx

# İnteraktif terminal aç
docker run -it debian bash
docker run -it debian sh        # bash yoksa sh kullan

# Durduğunda container'ı sil
docker run --rm debian echo "geçici"

# Port eşleme ile çalıştır  HOST_PORT:CONTAINER_PORT
docker run -d -p 8080:80 nginx          # host 8080 → container 80
docker run -d -p 443:443 -p 80:80 nginx # birden fazla port

# Ortam değişkeni ile çalıştır
docker run -d -e DB_HOST=localhost -e DB_PORT=3306 uygulamam

# Volume ile çalıştır
docker run -d -v volume_adim:/app/data uygulamam

# Ağ ile çalıştır
docker run -d --network benim-agim uygulamam

# Kaynak limitleriyle çalıştır
docker run -d --memory="512m" --cpus="1.0" uygulamam

# Belirli kullanıcıyla çalıştır
docker run -d --user www-data uygulamam

# Çalışan container'ları listele
docker ps

# TÜM container'ları listele (çalışan + durmuş)
docker ps -a

# Sadece container ID'lerini listele
docker ps -q

# İsme göre filtrele
docker ps -f name=wordpress

# Duruma göre filtrele
docker ps -f status=exited

# Çıktıyı formatla
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Container'ı durdur (SIGTERM gönderir, bekler, sonra SIGKILL)
docker stop benim-nginx

# Özel timeout ile durdur (saniye)
docker stop -t 30 benim-nginx

# Durmuş container'ı başlat
docker start benim-nginx

# Container'ı yeniden başlat
docker restart benim-nginx

# Container'ı dondur (süreçleri askıya al)
docker pause benim-nginx

# Dondurulmuş container'ı devam ettir
docker unpause benim-nginx

# Container'ı anında öldür (SIGKILL gönderir, bekleme yok)
docker kill benim-nginx

# Durmuş container'ı sil
docker rm benim-nginx

# Çalışan container'ı zorla sil
docker rm -f benim-nginx

# Tüm durmuş container'ları sil
docker container prune

# Tüm container'ları sil (çalışan ve durmuş)
docker rm -f $(docker ps -aq)

# Container'ı yeniden adlandır
docker rename eski-isim yeni-isim
```

### Log ve İnceleme

```bash
# Tüm log'ları gör
docker logs benim-nginx

# Log'ları gerçek zamanlı takip et
docker logs -f benim-nginx

# Son 100 satırı göster
docker logs --tail 100 benim-nginx

# Zaman damgasıyla log'ları göster
docker logs -t benim-nginx

# Belirli bir zamandan bu yana log'ları göster
docker logs --since 2024-01-01T10:00:00 benim-nginx

# Son 30 dakikadaki log'ları göster
docker logs --since 30m benim-nginx

# Container'ı incele — tüm detaylar JSON olarak
docker inspect benim-nginx

# inspect'ten belirli bir alan al
docker inspect --format='{{.State.Status}}' benim-nginx
docker inspect --format='{{.NetworkSettings.IPAddress}}' benim-nginx

# Canlı kaynak kullanımını gör (CPU, bellek, ağ, disk)
docker stats

# Kaynak kullanımını bir kez göster (canlı değil)
docker stats --no-stream

# Canlı süreç ve kaynak kullanımı
docker top benim-nginx

# Container'ın port eşlemelerini gör
docker port benim-nginx

# Container içindeki dosya sistemi değişikliklerini gör
docker diff benim-nginx
```

### Container İçinde Komut Çalıştırma

```bash
# İnteraktif shell aç
docker exec -it benim-nginx bash
docker exec -it benim-nginx sh       # bash yoksa

# Tek bir komut çalıştır
docker exec benim-nginx nginx -t     # nginx konfigürasyonunu test et
docker exec benim-nginx ls /etc/nginx

# Belirli kullanıcıyla çalıştır
docker exec -u root benim-nginx bash
docker exec -u www-data benim-nginx bash

# Container'dan host'a dosya kopyala
docker cp benim-nginx:/etc/nginx/nginx.conf ./nginx.conf

# Host'tan container'a dosya kopyala
docker cp ./benim-konfig.conf benim-nginx:/etc/nginx/nginx.conf
```

### Volume'lar

```bash
# Tüm volume'ları listele
docker volume ls

# İsimli volume oluştur
docker volume create benim-verim

# Volume'u incele — verinin host'ta nerede olduğunu gör
docker volume inspect benim-verim

# Volume'u sil (hiçbir container tarafından kullanılmıyorsa)
docker volume rm benim-verim

# Kullanılmayan tüm volume'ları sil
docker volume prune
```

### Ağlar

```bash
# Tüm ağları listele
docker network ls

# Bridge ağı oluştur
docker network create benim-agim

# Ağı incele — bağlı container'ları, IP aralıklarını gör
docker network inspect benim-agim

# Ağı sil
docker network rm benim-agim

# Kullanılmayan ağları sil
docker network prune

# Çalışan bir container'ı ağa bağla
docker network connect benim-agim benim-container

# Container'ı ağdan ayır
docker network disconnect benim-agim benim-container
```

### Sistem

```bash
# Docker disk kullanımının dökümünü gör
docker system df

# Ayrıntılı disk kullanımını gör
docker system df -v

# Kullanılmayan tüm kaynakları kaldır (container, image, ağ)
docker system prune

# Volume dahil kullanılmayan tüm kaynakları kaldır
docker system prune --volumes

# Etiketli image'lar dahil her şeyi kaldır
docker system prune -a

# Volume dahil her şeyi kaldır — TAM SIFIRLAMA
docker system prune -a --volumes

# Docker sürümünü göster
docker version

# Docker sistem bilgisini göster
docker info
```

---

## Docker Compose Komutları

Bu komutları `docker-compose.yml` dosyasının bulunduğu dizinde çalıştır ya da `-f` ile dosyayı belirt.

```bash
# Tüm servisleri başlat (gerekirse oluşturur)
docker-compose up

# Arka planda başlat
docker-compose up -d

# Başlamadan önce tüm image'ları yeniden oluştur
docker-compose up -d --build

# Sadece bir servisi yeniden oluştur
docker-compose up -d --build wordpress

# Belirli bir compose dosyası kullan
docker-compose -f srcs/docker-compose.yml up -d --build

# Tüm servisleri durdur (container'lar kalır, sadece durdurulur)
docker-compose stop

# Bir servisi durdur
docker-compose stop nginx

# Container'ları durdur ve kaldır (volume ve image'lar kalır)
docker-compose down

# Container'ları durdur, kaldır VE volume'ları sil (veri silinir)
docker-compose down -v

# Container'ları, volume'ları VE image'ları sil
docker-compose down -v --rmi all

# Tüm servisleri yeniden başlat
docker-compose restart

# Bir servisi yeniden başlat
docker-compose restart nginx

# Tüm servislerin durumunu gör
docker-compose ps

# Tüm servislerin log'larını gör
docker-compose logs

# Tüm servislerin log'larını takip et
docker-compose logs -f

# Bir servisin log'larını takip et
docker-compose logs -f wordpress

# Bir servisin son 50 satır log'unu gör
docker-compose logs --tail 50 mariadb

# Çalışan bir serviste komut çalıştır
docker-compose exec wordpress bash
docker-compose exec mariadb mysql -u root -p

# Tek seferlik komut çalıştır (geçici container başlatır)
docker-compose run --rm wordpress wp --info

# Image'ları başlatmadan oluştur
docker-compose build

# Cache kullanmadan oluştur (tam yeniden oluşturma)
docker-compose build --no-cache

# Compose dosyasında tanımlı image'ları çek
docker-compose pull

# Compose tarafından kullanılan image'ları listele
docker-compose images

# Değişken yerine koyma sonrası konfigürasyonu göster
docker-compose config
```

---

## Dockerfile — Derinlemesine

### Tüm Komutların Açıklaması

```dockerfile
# FROM — temel image, her zaman ilk satır
# Belirli sürüm etiketleri kullan, asla "latest" kullanma
FROM debian:bookworm

# LABEL — image hakkında metadata
LABEL maintainer="merilhan@42.fr"
LABEL version="1.0"

# ARG — derleme zamanı değişkeni (sadece build sırasında kullanılabilir, çalışma zamanında değil)
ARG UYGULAMA_SURUMU=1.0
RUN echo "$UYGULAMA_SURUMU sürümü derleniyor"

# ENV — çalışma zamanı ortam değişkeni (container'da da kullanılabilir)
ENV UYGULAMA_EVI=/var/www
ENV NODE_ENV=production

# RUN — derleme sırasında komut çalıştır
# Her zaman && ile komutları birleştir, katman sayısını azalt
# Sonunda apt cache'i temizle
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

# COPY — build context'ten image'a dosya kopyala
# Basit dosya kopyalama için ADD'den tercih edilir
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/baslat.sh /baslat.sh

# ADD — COPY gibi ama URL ve tar çıkarma da destekler
# Bu ekstra özelliklere ihtiyaç duyduğunda ADD kullan
ADD https://example.com/dosya.tar.gz /tmp/
# Bu tar'ı otomatik çıkarır:
ADD arsiv.tar.gz /usr/local/

# WORKDIR — çalışma dizinini ayarla (cd gibi ama kalıcı)
# Dizin yoksa oluşturur
WORKDIR /var/www/html

# USER — sonraki komutları bu kullanıcı olarak çalıştır
RUN useradd -m uygulamakullanicisi
USER uygulamakullanicisi

# EXPOSE — container'ın kullandığı portu belgele
# Bu gerçekten portu açmaz — sadece dokümantasyon
EXPOSE 80
EXPOSE 443

# VOLUME — mount noktası bildir
VOLUME /var/www/html

# ENTRYPOINT — ana komut, her zaman çalışır
# Exec form kullan (JSON dizisi) — süreci PID 1 yapar
ENTRYPOINT ["nginx", "-g", "daemon off;"]

# CMD — ENTRYPOINT için varsayılan argümanlar veya varsayılan komut
# docker run argümanlarıyla geçersiz kılınabilir
CMD ["--help"]
```

### COPY vs ADD

```dockerfile
# Basit dosya işlemleri için COPY kullan
COPY src/uygulama.py /uygulama/uygulama.py
COPY ./konfig/ /etc/uygulamam/

# Sadece şunlara ihtiyaç duyduğunda ADD kullan:
# 1. URL'den indirme
ADD https://example.com/dosya.txt /tmp/dosya.txt

# 2. Otomatik tar çıkarma
ADD arsivim.tar.gz /usr/local/

# Diğer her şey için COPY daha iyidir çünkü:
# - Daha açık ve öngörülebilir
# - URL'li ADD build cache'i düzgün kullanmıyor
```

### ARG vs ENV

```dockerfile
# ARG — sadece derleme zamanında kullanılabilir
# Kullanım: sürüm numaraları, derleme bayrakları
ARG PHP_SURUMU=8.2
RUN apt-get install -y php${PHP_SURUMU}-fpm

# ENV — hem derleme hem çalışma zamanında kullanılabilir
# Kullanım: uygulama konfigürasyonu, yollar
ENV UYGULAMA_ORTAMI=production
ENV DB_HOST=mariadb

# ARG'dan ENV oluştur
ARG BUILD_ENV=production
ENV UYGULAMA_ORTAMI=${BUILD_ENV}

# Derleme zamanında ARG'ı geçersiz kıl:
# docker build --build-arg PHP_SURUMU=8.1 .

# Çalışma zamanında ENV'i geçersiz kıl:
# docker run -e UYGULAMA_ORTAMI=development uygulamam
```

### .dockerignore

`.gitignore` gibi, `.dockerignore` da Docker'a image oluştururken hangi dosyaları yok sayacağını söyler. Build'leri hızlandırır ve image'ları küçük tutar.

```
# .dockerignore dosyası (Dockerfile ile aynı dizine koy)

# Git dosyalarını yok say
.git
.gitignore

# Dokümantasyonu yok say
README.md
*.md

# Geliştirme dosyalarını yok say
node_modules/
*.log
.env

# Test dosyalarını yok say
tests/
*.test.js

# İşletim sistemi dosyalarını yok say
.DS_Store
Thumbs.db
```

---

## Docker Katmanları ve Build Cache

### Katmanlar Nasıl Çalışır

Dockerfile'daki her komut yeni bir katman oluşturur. Katmanlar birbiri üzerine yığılır. Her katman yalnızca önceki katmandan gelen değişiklikleri içerir.

```
Katman 4: COPY tools/baslat.sh /baslat.sh   (2KB ekler)
Katman 3: RUN apt-get install -y nginx        (50MB ekler)
Katman 2: RUN apt-get update                  (20MB ekler)
Katman 1: FROM debian:bookworm                (115MB ekler)
```

Toplam image boyutu = tüm katmanların toplamı.

### Build Cache

Docker her katmanı önbelleğe alır. Image'ı yeniden oluştururken Docker değişip değişmediğini kontrol eder. Katman öncekiyle aynıysa Docker yeniden oluşturmak yerine önbelleğe alınan sürümü kullanır.

```
# İlk build: tüm katmanlar sıfırdan oluşturulur
Adım 1/4 : FROM debian:bookworm      → internetten çekildi
Adım 2/4 : RUN apt-get update        → çalıştırıldı
Adım 3/4 : RUN apt-get install nginx → çalıştırıldı (30 saniye sürdü)
Adım 4/4 : COPY nginx.conf /etc/...  → çalıştırıldı

# İkinci build (nginx.conf değişti):
Adım 1/4 : FROM debian:bookworm      → Cache kullanılıyor ✓
Adım 2/4 : RUN apt-get update        → Cache kullanılıyor ✓
Adım 3/4 : RUN apt-get install nginx → Cache kullanılıyor ✓
Adım 4/4 : COPY nginx.conf /etc/...  → çalıştırıldı (cache geçersiz)
```

### Cache Geçersiz Kılma

Bir katman değiştiğinde, sonrasındaki tüm katmanlar da yeniden oluşturulur. Bu yüzden komutların sırası önemlidir.

```dockerfile
# KÖTÜ — uygulama.py değiştiğinde apt-get yeniden çalışmak zorunda
COPY uygulama.py /uygulama/
RUN apt-get install -y python3      # uygulama.py değişince her zaman yeniden oluşur

# İYİ — önce paketleri kur (nadiren değişirler)
RUN apt-get install -y python3      # Dockerfile değişmeden cache'de kalır
COPY uygulama.py /uygulama/         # sadece bu ve sonrası değişince yeniden oluşur
```

### Cache Olmadan Yeniden Oluştur

```bash
docker build --no-cache -t uygulamam .
docker-compose build --no-cache
```

---

## Docker Ağları — Derinlemesine

### Ağ Türleri

**Bridge (köprü — varsayılan)** — Özel bir iç ağ oluşturur. Aynı bridge ağındaki container'lar birbirleriyle konuşabilir. Farklı bridge ağlarındaki container'lar doğrudan konuşamaz.

```bash
docker network create --driver bridge benim-agim
```

**Host** — Container host'un ağını doğrudan kullanır. İzolasyon yok. Container'daki port 80, host'taki port 80'dir. Bu projede yasak.

```bash
docker run --network host nginx
```

**None** — Hiç ağ yok. Container hiçbir şeyle iletişim kuramaz.

```bash
docker run --network none debian
```

### Container DNS Nasıl Çalışır

Özel bir bridge ağında Docker dahili bir DNS sunucusu çalıştırır. Her container, servis adıyla eşit bir DNS girişi alır. WordPress, MariaDB'ye bağlanmak istediğinde sadece `mariadb`'yi hostname olarak kullanır — Docker'ın DNS'i bunu otomatik olarak doğru container IP'sine çözer.

```
WordPress container:
  "mariadb:3306'ya bağlan"
         ↓
  Docker dahili DNS (127.0.0.11)
         ↓
  "mariadb = 172.18.0.3"
         ↓
  172.18.0.3:3306'ya TCP bağlantısı
         ↓
  MariaDB container
```

### Ağ Trafiğini İncele

```bash
# Hangi container'ların hangi ağda olduğunu gör
docker network inspect dev_net

# Bir container'ın IP'sini gör
docker inspect --format='{{.NetworkSettings.Networks.srcs_dev_net.IPAddress}}' wordpress

# Tüm container IP'lerini gör
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q)
```

---

## Docker Volume'ları — Derinlemesine

### Volume Türleri

**İsimli Volume'lar** — Docker tarafından yönetilir. İsimleri vardır. `docker volume inspect` ile inceleyebilirsin.

```yaml
volumes:
  benim-verim:          # isimli volume, Docker konumu yönetir

services:
  uygulama:
    volumes:
      - benim-verim:/uygulama/veri
```

**Anonim Volume'lar** — İsimli volume'lar gibi ama rastgele ID'li isimle. Compose'da isim belirtmeden Dockerfile'da `VOLUME` kullandığında oluşur.

**Bind Mount'lar** — Host'taki tam yolu belirtirsin. Docker tarafından yönetilmez. `docker volume ls`'de görünmez.

```yaml
services:
  uygulama:
    volumes:
      - /home/kullanici/veri:/uygulama/veri  # bind mount
```

**tmpfs Mount'lar** — Host belleğinde saklanır, diskte değil. Container durduğunda gider.

### Bu Projenin Yaklaşımı — Özel Yollu İsimli Volume

```yaml
volumes:
  wp_vol:
    driver: local
    driver_opts:
      type: none          # özel dosya sistemi türü yok
      device: /home/merilhan/data/wordpress   # host yolu
      o: bind             # mount seçeneği: bind
```

Bu isimli bir volume (`docker volume ls`'de görünür) ve belirli bir konumda veri saklar. `o: bind` bir Linux kernel mount seçeneğidir, compose sözdizimindeki Docker "bind mount"u ile aynı şey değildir.

```bash
# İsimli volume olduğunu doğrula
docker volume ls
# DRIVER    VOLUME NAME
# local     srcs_db_vol
# local     srcs_wp_vol

docker volume inspect srcs_wp_vol
# "Driver": "local"
# "Options": {"device": "/home/merilhan/data/wordpress", "o": "bind", "type": "none"}
```

---

## Docker Secrets — Derinlemesine

### Docker Compose'da Secrets Nasıl Çalışır

Docker Compose dosya tabanlı secrets şöyle çalışır:

1. Host makinende gizli değeri içeren bir dosya var (örn. `secrets/db_password.txt` içeriği `sifrem123`)
2. `docker-compose.yml`'de secret'ı bildiriyorsun
3. Secret'ı ihtiyaç duyan servislere atıyorsun
4. Docker dosyayı `/run/secrets/secret-adı`'nda her servis container'ına mount ediyor
5. Container script'i değeri `cat /run/secrets/secret-adı` ile okuyor

```yaml
# docker-compose.yml

secrets:
  db_password:
    file: ../secrets/db_password.txt    # host'taki kaynak dosya

services:
  mariadb:
    secrets:
      - db_password    # container içinde /run/secrets/db_password'a mount edilir
  wordpress:
    secrets:
      - db_password    # aynı dosya, burada da mevcut
```

```sh
# Container script'i içinde:
DB_PASSWORD=$(cat /run/secrets/db_password)
echo "Şifre: $DB_PASSWORD"
```

### Neden Şifreler İçin Ortam Değişkeni Kullanmayalım?

```bash
# Ortam değişkenlerini şifre için kullanırsan:
docker inspect wordpress
# TÜM ortam değişkenlerini düz metin olarak görebilirsin:
# "DB_PASSWORD": "benimgizlisifrem"
# docker inspect erişimi olan herkes tüm şifreleri okuyabilir

# Secrets ile:
docker inspect wordpress
# Sadece "db_password" mount edilmiş gösterir — değeri değil
# Gerçek değer sadece container içinden görülebilir
```

| | Ortam Değişkenleri | Docker Secrets |
|---|---|---|
| `docker inspect`'te görünür | Evet, düz metin | Hayır |
| Log'larda görünür | Bazen | Nadiren |
| Container içi erişim | `$DEGISKEN` | `cat /run/secrets/ad` |
| Git'te commit edilirse riski | Çok yüksek | Yok (dosya ayrı) |

---

## PID 1 ve Sinyal Yönetimi

### PID 1 Nedir?

Her Linux sürecinin bir ID'si (PID) vardır. Başlayan ilk süreç PID 1'i alır. Normal bir Linux sisteminde PID 1 `init` veya `systemd`'dir. Docker container'ında PID 1, `ENTRYPOINT` veya `CMD`'nin çalıştırdığı şeydir.

PID 1 özeldir çünkü:
- Docker bir container'ı durdurduğunda PID 1'e `SIGTERM` gönderir
- PID 1 10 saniye içinde çıkmazsa Docker `SIGKILL` (zorla öldürme) gönderir
- PID 1, "zombie" alt süreçleri toplamaktan sorumludur

### Exec Form vs Shell Form

```dockerfile
# SHELL FORM — /bin/sh -c aracılığıyla çalışır
# Shell PID 1 olur, gerçek programın değil
ENTRYPOINT nginx -g "daemon off;"
# Container süreç ağacı:
# PID 1: /bin/sh -c nginx -g "daemon off;"
# PID 2: nginx -g "daemon off;"
# Docker SIGTERM gönderince sh bunu nginx'e iletmeyebilir → temiz olmayan kapanış

# EXEC FORM — doğrudan çalışır, shell sarıcısı yok
# Gerçek programın kendisi PID 1 olur
ENTRYPOINT ["nginx", "-g", "daemon off;"]
# Container süreç ağacı:
# PID 1: nginx -g "daemon off;"
# SIGTERM doğrudan nginx'e gider → temiz kapanış
```

`ENTRYPOINT` ve `CMD` için her zaman exec form (JSON dizi formatı) kullan. Bu yüzden bu projedeki tüm script'ler şunu kullanır:

```sh
exec php-fpm8.2 -F      # "exec" shell'i php-fpm ile değiştirir — PID 1 olur
exec mysqld --user=mysql # "exec" mysqld'yi PID 1 yapar
exec vsftpd /etc/vsftpd.conf
```

### NGINX'te daemon off Nedir?

Varsayılan olarak NGINX başlar ve hemen kendini arka plana atar (daemonize). Docker container'ında bu bir sorundur — süreç arka plana geçerse ön planda süreç kalmaz ve Docker container'ın bittiğini sanarak onu durdurur.

`daemon off;` NGINX'e ön planda kalmasını söyler. Bu sayede NGINX PID 1 olur ve Docker container'ı çalışır durumda tutar.

---

## Bu Projede Kullanılan Servisler

### NGINX

NGINX bir web sunucusu ve ters proxy'dir. Bu projede birkaç şey yapar:

1. **SSL'i sonlandırır** — tarayıcıdan gelen HTTPS trafiğini şifreler/çözer
2. **WordPress'e hizmet eder** — PHP isteklerini PHP-FPM'e iletir
3. **Ters proxy** — `/adminer/`, `/portainer/`, `/portfolio/`'yu doğru container'lara yönlendirir
4. **Tek giriş noktası** — dışarıya açık portu olan tek container (443)

### MariaDB

MariaDB ilişkisel bir veritabanıdır — MySQL'in bir fork'u. WordPress tüm içeriği burada saklar: gönderiler, sayfalar, kullanıcılar, ayarlar, her şey.

Sadece Docker iç ağında çalışır. İnternetten doğrudan erişilemez. Sadece WordPress ve Adminer `dev_net` ağı üzerinden bağlanabilir.

### PHP-FPM

PHP-FPM (FastCGI Süreç Yöneticisi) PHP kodunu çalıştırır. NGINX tek başına PHP çalıştıramaz — PHP dosyalarını PHP-FPM'e verir, PHP-FPM işler ve HTML sonucunu geri gönderir.

PHP-FPM port 9000'de dinler. NGINX ve PHP-FPM FastCGI protokolüyle iletişim kurar.

### Redis

Redis, bellekte çalışan bir veri deposudur. Disk yerine her şeyi RAM'de sakladığı için son derece hızlıdır.

WordPress Redis'i nesne önbelleği olarak kullanır. WordPress veritabanından bir şey çektiğinde (örn. ana sayfa içeriği) bir kopyasını Redis'e kaydeder. Bir sonraki ziyarette WordPress, MariaDB'yi sorgulamak yerine Redis'ten veri alır. Çok daha hızlıdır.

### vsftpd (FTP Sunucusu)

vsftpd (Very Secure FTP Daemon — Çok Güvenli FTP Daemon) bir FTP sunucusudur. WordPress volume'una doğrudan dosya erişimi sağlar. Herhangi bir FTP istemcisiyle bağlanıp WordPress dosyalarına göz atabilir, yükleyebilir veya indirebilirsin.

### Adminer

Adminer tek bir PHP dosyasında yazılmış bir veritabanı yönetim aracıdır. MariaDB veritabanına göz atmak için tarayıcı arayüzü sağlar.

### Portainer

Portainer Docker yönetim arayüzüdür. Tüm container'ları, log'larını, kaynak kullanımını, volume'ları ve ağları web tarayıcısından görmeni sağlar.

---

## Bir Web İsteği Adım Adım Nasıl Çalışır

Tarayıcına `https://merilhan.42.fr` yazınca:

```
1. Tarayıcı → DNS sorgusu
   "merilhan.42.fr'nin IP'si ne?"
   /etc/hosts der ki: 127.0.0.1
   Yani istek localhost'a gider

2. Tarayıcı → 127.0.0.1:443'e TCP bağlantısı

3. Host makinesi → port 443 NGINX container'ına yönlendirilir
   (docker-compose'daki "ports: 443:443" nedeniyle)

4. NGINX → SSL el sıkışması
   NGINX kendinden imzalı sertifikasını sunar
   Tarayıcı "Güvenli değil" uyarısı verir (kendinden imzalı olduğu için)
   Kabul ettikten sonra trafik şifreli

5. NGINX → HTTP isteğini alır
   "GET / HTTP/1.1"
   "Host: merilhan.42.fr"

6. NGINX → /var/www/wordpress'te dosya var mı kontrol eder
   "/var/www/wordpress/index.php var mı?"
   Evet → PHP-FPM'e ilet

7. NGINX → wordpress:9000'e FastCGI isteği
   "/var/www/wordpress/index.php'yi çalıştır"
   "Sorgu dizisi: ?"
   "Sunucu adı: merilhan.42.fr"

8. PHP-FPM → index.php'yi çalıştırır
   WordPress yüklenir
   WordPress içerik için MariaDB'yi sorgular
   WordPress Redis önbelleğini kontrol eder (önbellekte varsa MariaDB'yi atla)
   WordPress HTML sayfası oluşturur

9. PHP-FPM → HTML'i NGINX'e geri gönderir

10. NGINX → HTTP 200 OK ile HTML'i tarayıcıya gönderir

11. Tarayıcı → sayfayı render eder
```

### /adminer/ İstekleri İçin:

```
Tarayıcı → https://merilhan.42.fr/adminer/
NGINX → location /adminer/ eşleşir
NGINX → http://adminer:8080/'e proxy_pass
Adminer container → Adminer PHP dosyasını sunar
Adminer → giriş yapınca mariadb:3306'ya bağlanır
```

---

## SSL ve HTTPS Açıklaması

### SSL/TLS Nedir?

SSL (Güvenli Yuva Katmanı) ve halefi TLS (Aktarım Katmanı Güvenliği), internet trafiğini şifreleyen protokollerdir. HTTPS = HTTP + TLS.

HTTPS olmadan, ağındaki herkes gönderip aldıklarını okuyabilir (şifreler, çerezler, içerik).

HTTPS ile:
1. Tarayıcı ve sunucu şifreleme yöntemini belirler
2. Sunucu kimliğini kanıtlayan sertifika gönderir
3. Her iki taraf şifreleme anahtarları oluşturur
4. Tüm trafik şifrelenir — aradaki kimse okuyamaz

### TLS Sürümleri

- **TLS 1.0, 1.1** — eski ve güvensiz, devre dışı
- **TLS 1.2** — güvenli, geniş destek, bu projede izin verilen
- **TLS 1.3** — en yeni, daha hızlı, en güvenli, bu projede izin verilen
- **SSL 2.0, 3.0** — tamamen kırık, asla kullanma

Bu projenin NGINX konfigürasyonu sadece TLS 1.2 ve 1.3'e izin verir:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

### Sertifika Nedir?

Sertifika kim olduğunu kanıtlayan bir dosyadır. Şunları içerir:
- Alan adın
- Açık anahtarın
- Geçerlilik süresi
- Sertifika Otoritesi'nin (CA) imzası

**Kendinden imzalı sertifika** kendin tarafından imzalanmıştır. Tarayıcılar varsayılan olarak güvenmez ve uyarı gösterir. Geliştirme için sorun değil — production'da Let's Encrypt (ücretsiz) veya ücretli CA kullanırsın.

### Sertifikayı Nasıl Oluşturuyoruz

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=merilhan.42.fr"
```

- `-x509` — sertifika isteği değil, kendinden imzalı sertifika oluştur
- `-nodes` — özel anahtarı şifreleme (NGINX şifresiz okuyabilsin)
- `-days 365` — 1 yıl geçerli
- `-newkey rsa:2048` — yeni 2048-bit RSA anahtar çifti oluştur
- `-keyout` — özel anahtarı buraya kaydet
- `-out` — sertifikayı buraya kaydet
- `-subj` — sertifika detayları (ülke, il, şehir, kurum, alan adı)

---

## NGINX Konfigürasyonu Açıklaması

```nginx
server {
    # Port 443'te SSL ile dinle
    listen 443 ssl;

    # Bu server bloğunun yanıt verdiği alan adı
    server_name merilhan.42.fr;

    # Sadece TLS 1.2 ve 1.3'e izin ver — eski sürümler güvensiz
    ssl_protocols TLSv1.2 TLSv1.3;

    # Sertifika ve özel anahtar dosyaları
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # Dosyalar için varsayılan dizin
    root /var/www/wordpress;

    # Birisi dizin istediğinde bu dosyaları dene
    index index.php index.html index.htm;

    # Tüm istekleri işle
    location / {
        # Dosyayı dene, sonra dizini, sonra index.php'ye geri düş
        # WordPress yönlendirmesini çalıştırır (güzel URL'ler)
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP dosyalarını işle — PHP-FPM'e ilet
    location ~ \.php$ {
        # Yolu böl: /index.php/bir/yol → /index.php + /bir/yol
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        # wordpress:9000'deki PHP-FPM'e gönder
        fastcgi_pass wordpress:9000;

        # Dizin istenirse varsayılan dosya
        fastcgi_index index.php;

        # Standart FastCGI parametrelerini ekle
        include fastcgi_params;

        # PHP'ye script dosyasının nerede olduğunu söyle
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    # Portfolio için proxy — yol öneki korunuyor
    location /portfolio/ {
        # proxy_pass'ta sondaki eğik çizgi yok — /portfolio/ öneki korunur
        proxy_pass http://static:80;
    }

    # Adminer için proxy
    location /adminer/ {
        # Sondaki eğik çizgi var — /adminer/ öneki çıkarılır, geri kalan iletilir
        proxy_pass http://adminer:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Portainer için proxy — WebSocket desteği gerekli
    location /portainer/ {
        proxy_pass http://portainer:9000/;

        # WebSocket desteği (Portainer canlı güncellemeler için WebSocket kullanır)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### proxy_pass URL Kuralları

`proxy_pass`'taki sondaki eğik çizgi çok önemli:

```nginx
# Sondaki EĞİK ÇİZGİ VAR — konum önekini çıkarır
location /adminer/ {
    proxy_pass http://adminer:8080/;
    # İstek: /adminer/index.php
    # Gönderilen: http://adminer:8080/index.php   ← /adminer/ çıkarıldı
}

# Sondaki EĞİK ÇİZGİ YOK — tam yolu korur
location /portfolio/ {
    proxy_pass http://static:80;
    # İstek: /portfolio/static/js/main.js
    # Gönderilen: http://static:80/portfolio/static/js/main.js   ← korundu
}
```

---

## PHP-FPM ve FastCGI Açıklaması

### PHP-FPM Nedir?

PHP-FPM, PHP için bir süreç yöneticisidir. PHP süreçlerini çalışır durumda ve istekleri işlemeye hazır tutar. İstek gelince PHP-FPM onu hazır süreçlerden birine verir, o süreç PHP dosyasını çalıştırır ve sonucu döndürür.

NGINX tek başına PHP çalıştıramaz. PHP-FPM, NGINX ve PHP arasındaki köprüdür.

```
Tarayıcı → NGINX (HTTP, SSL işler)
              ↓ FastCGI protokolü
          PHP-FPM (PHP kodu çalıştırır)
              ↓ SQL sorguları
          MariaDB (veri saklar)
```

### FastCGI Nedir?

FastCGI, bir web sunucusu ile uygulama arasındaki iletişim protokolüdür. Eski CGI'dan daha hızlıdır çünkü:
- CGI her istek için yeni süreç başlatır — yavaş
- FastCGI süreçleri çalışır durumda tutar ve yeniden kullanır — hızlı

### www.conf — PHP-FPM Havuz Konfigürasyonu

```ini
[www]
; Bu kullanıcı olarak çalış
user = www-data
group = www-data

; Port 9000'de dinle — NGINX buraya bağlanır
listen = 0.0.0.0:9000

; Süreç yönetimi modu
pm = ondemand         ; işçileri sadece gerektiğinde başlat (bellek tasarrufu)
; pm = static         ; her zaman N işçi çalıştır
; pm = dynamic        ; bazılarını çalışır tut, meşgulken daha fazla başlat

; Maksimum işçi sayısı
pm.max_children = 5

; Tüm ortam değişkenlerini PHP süreçlerine ilet
; Bu olmadan WordPress ortam değişkenlerini okuyamaz
clear_env = no
```

---

## MariaDB — Faydalı Komutlar

### MariaDB'ye Bağlan

```bash
# Host'tan docker exec kullanarak
docker exec -it $(docker ps -q -f name=mariadb) mysql -u wp_manager -p wordpress_db

# Container içinden
mysql -u root -p
mysql -u wp_manager -pSIFREN wordpress_db
```

### Faydalı SQL Komutları

```sql
-- Tüm veritabanlarını göster
SHOW DATABASES;

-- Belirli bir veritabanını kullan
USE wordpress_db;

-- Tüm tabloları göster
SHOW TABLES;

-- Tablo yapısını göster
DESCRIBE wp_users;
DESCRIBE wp_posts;

-- Tablodaki satırları say
SELECT COUNT(*) FROM wp_posts;

-- Tüm WordPress kullanıcılarını göster
SELECT user_login, user_email, user_registered FROM wp_users;

-- Yayınlanmış tüm gönderileri göster
SELECT ID, post_title, post_status FROM wp_posts WHERE post_status = 'publish';

-- WordPress ayarlarını göster
SELECT option_name, option_value FROM wp_options
WHERE option_name IN ('siteurl', 'blogname', 'admin_email');

-- Veritabanı boyutunu kontrol et
SELECT
  table_schema AS "Veritabanı",
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Boyut (MB)"
FROM information_schema.tables
GROUP BY table_schema;

-- Aktif bağlantıları göster
SHOW PROCESSLIST;

-- Mevcut kullanıcıyı göster
SELECT USER();

-- Bir kullanıcının tüm yetkilerini göster
SHOW GRANTS FOR 'wp_manager'@'%';
```

### MariaDB Yedekleme ve Geri Yükleme

```bash
# Veritabanını SQL dosyasına yedekle
docker exec $(docker ps -q -f name=mariadb) \
  mysqldump -u root -p wordpress_db > yedek.sql

# SQL dosyasından veritabanını geri yükle
docker exec -i $(docker ps -q -f name=mariadb) \
  mysql -u root -p wordpress_db < yedek.sql
```

---

## Redis — Faydalı Komutlar

### Redis'e Bağlan

```bash
# Redis CLI'ya bağlan
docker exec -it $(docker ps -q -f name=redis) redis-cli

# Bağlantıyı test et
docker exec -it $(docker ps -q -f name=redis) redis-cli ping
# Yanıt vermelidir: PONG
```

### Faydalı Redis Komutları

```bash
# redis-cli içinde:

# Redis çalışıyor mu?
PING
# → PONG

# Anahtar-değer çifti oluştur
SET anahtarim "merhaba"

# Değer al
GET anahtarim
# → "merhaba"

# Süre sonu ile oluştur (saniye)
SET anahtarim "merhaba" EX 3600

# Kalan süreyi kontrol et
TTL anahtarim

# Anahtarı sil
DEL anahtarim

# Tüm anahtarları listele (büyük veri setlerinde dikkatli — yavaş)
KEYS *

# Kalıba göre anahtarları listele
KEYS wordpress:*

# Toplam anahtar sayısı
DBSIZE

# Sunucu bilgisi
INFO

# Bellek kullanım istatistikleri
INFO memory

# İsabet/kaçırma istatistikleri (önbellek çalışıyor mu?)
INFO stats
# keyspace_hits ve keyspace_misses'a bak
# hits/(hits+misses) = önbellek isabet oranı

# Tüm verileri sil (DİKKATLİ — her şeyi siler)
FLUSHALL

# Tüm komutları gerçek zamanlı izle
MONITOR
```

### WordPress Önbelleğinin Çalışıp Çalışmadığını Kontrol Et

```bash
# İki terminal aç

# Terminal 1 — Redis'i gerçek zamanlı izle
docker exec -it $(docker ps -q -f name=redis) redis-cli MONITOR

# Terminal 2 — siteyi ziyaret et
curl -sk https://merilhan.42.fr > /dev/null

# Terminal 1'de GET/SET komutları görmelisin
# Bu WordPress'in Redis'e okuyup yazdığı anlamına gelir
```

---

## WP-CLI — WordPress'i Terminalden Yönetmek

WP-CLI, WordPress'i yönetmek için komut satırı aracıdır. WordPress container'ına kurulur.

```bash
# WordPress container'ında WP-CLI çalıştır
docker exec -it $(docker ps -q -f name=wordpress) sh

# Container içinde:
wp --info                          # WP-CLI sürümünü kontrol et
wp core version                    # WordPress sürümünü kontrol et
wp core check-update               # güncellemeleri kontrol et

# Kullanıcı yönetimi
wp user list                       # tüm kullanıcıları listele
wp user get admin --field=email   # kullanıcı e-postasını al
wp user create yenikullanici kullanici@ornek.com --role=subscriber --user_pass=sifre123
wp user delete 2                   # ID'si 2 olan kullanıcıyı sil
wp user update 1 --user_pass=yenisifre  # şifre değiştir

# Eklenti yönetimi
wp plugin list                     # tüm eklentileri listele
wp plugin install redis-cache      # eklenti kur
wp plugin activate redis-cache     # eklentiyi etkinleştir
wp plugin deactivate redis-cache   # eklentiyi devre dışı bırak
wp plugin delete redis-cache       # eklentiyi sil
wp plugin update --all             # tüm eklentileri güncelle

# Tema yönetimi
wp theme list                      # tüm temaları listele
wp theme activate twentytwentyone  # tema etkinleştir

# Veritabanı
wp db check                        # veritabanı bağlantısını kontrol et
wp db export yedek.sql             # veritabanını dışa aktar
wp db import yedek.sql             # veritabanını içe aktar
wp db query "SELECT * FROM wp_users"  # SQL sorgusu çalıştır

# Seçenekler (WordPress ayarları)
wp option get siteurl              # site URL'sini al
wp option update siteurl "https://merilhan.42.fr"  # site URL'sini güncelle
wp option get blogname             # site başlığını al

# Önbellek
wp cache flush                     # nesne önbelleğini temizle
wp redis status                    # Redis durumunu kontrol et
wp redis enable                    # Redis önbelleğini etkinleştir
wp redis disable                   # Redis önbelleğini devre dışı bırak

# Konfigürasyon
wp config list                     # wp-config.php değerlerini listele
wp config get DB_HOST              # bir değeri al
wp config set DB_HOST mariadb      # bir değer ayarla

# Arama ve değiştirme
wp search-replace 'http://eski.com' 'https://yeni.com'  # veritabanındaki URL'leri güncelle
```

---

## FTP — Aktif ve Pasif Mod

### FTP Nedir?

FTP (Dosya Aktarım Protokolü) iki ayrı bağlantı kullanır:
1. **Kontrol bağlantısı** (port 21) — komut göndermek için
2. **Veri bağlantısı** — dosyaları gerçekten aktarmak için

Aktif ve pasif mod arasındaki fark, veri bağlantısını kimin oluşturduğudur.

### Aktif Mod

```
İstemci (rastgele port)  →  Sunucu port 21   (istemci kontrol için bağlanır)
Sunucu port 20           →  İstemci (rastgele) (SUNUCU veri için geri bağlanır)
```

Sorun: İstemci genellikle güvenlik duvarının veya NAT'ın arkasındadır. Sunucu istemciye geri bağlanamaz. Aktif mod bozulur.

### Pasif Mod

```
İstemci (rastgele port)  →  Sunucu port 21             (istemci kontrol için bağlanır)
İstemci (rastgele port)  →  Sunucu port 21100-21110    (İSTEMCİ veri için de bağlanır)
```

Sunucu istemciye "veri için port 21100'e bağlan" der. İstemci her iki bağlantıyı da açar. Güvenlik duvarları ve NAT üzerinden çalışır.

Bu yüzden docker-compose'da `21100-21110` portlarını expose ediyoruz — bunlar pasif mod veri portları.

### vsftpd Konfigürasyonu Açıklaması

```ini
listen=YES                    # bağlantıları dinle
listen_ipv6=NO               # IPv6 kullanma

anonymous_enable=NO          # anonim girişe izin verme
local_enable=YES             # sistem kullanıcılarının giriş yapmasına izin ver
write_enable=YES             # yükleme ve silmeye izin ver
local_umask=022              # yeni dosyalar 755 izni alır

chroot_local_user=YES        # kullanıcıları home dizinlerine kilitle
allow_writeable_chroot=YES   # chroot dizinine yazmaya izin ver

local_root=/var/www/wordpress # FTP kullanıcıları bağlandığında buraya gelir
secure_chroot_dir=/var/run/vsftpd/empty  # vsftpd güvenliği için gerekli

pasv_enable=YES              # pasif modu etkinleştir
pasv_min_port=21100          # ilk pasif port
pasv_max_port=21110          # son pasif port
```

---

## Kullanılan Shell Script Kalıpları

### Servis Hazır Olana Kadar Bekle

`sleep 20` yerine (güvenilmez), servis yanıt verene kadar yeniden dene:

```sh
# MariaDB hazır olana kadar WordPress kurulumunu dene
# wp core install DB hazır değilse başarısız olur, yeniden deneriz
until wp core install --url=https://${DOMAIN_NAME} \
                      --title="Sitem" \
                      --admin_user=yonetici \
                      --admin_password=$(cat /run/secrets/wp_admin_password) \
                      --admin_email=admin@ornek.com \
                      --allow-root; do
    echo "Veritabanı bekleniyor..."
    sleep 2
done
```

### Dosyadan Secret Oku

```sh
# Çalışma zamanında secret oku
SIFREM=$(cat /run/secrets/sifrem)

# Değişkende saklamadan anında kullan (daha güvenli)
echo "kullanici:$(cat /run/secrets/sifrem)" | chpasswd
```

### Kurulumun Tamamlanıp Tamamlanmadığını Kontrol Et

```sh
# Sadece bir kez kurulum yap — kurulumun oluşturduğu bir dosyayı kontrol et
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    echo "İlk çalışma — WordPress kuruluyor..."
    # kurulum yap
fi
# Her zaman servisi başlatmaya devam et
exec php-fpm8.2 -F
```

### PID 1 Olmak İçin exec Kullan

```sh
#!/bin/sh

# Kurulum yap
mkdir -p /run/php
chown -R www-data:www-data /var/www

# exec bu shell'i php-fpm ile değiştirir
# php-fpm PID 1 olur ve sinyalleri düzgün alır
exec php-fpm8.2 -F
```

### Çok Satırlı SQL İçin Heredoc

```sh
cat << EOF > /tmp/kurulum.sql
CREATE DATABASE IF NOT EXISTS \`${DB_ADI}\`;
CREATE USER IF NOT EXISTS '${DB_KULLANICI}'@'%' IDENTIFIED BY '${DB_SIFRESI}';
GRANT ALL PRIVILEGES ON \`${DB_ADI}\`.* TO '${DB_KULLANICI}'@'%';
FLUSH PRIVILEGES;
EOF
# Not: ters eğik çizgi + backtick → shell genişlemesini önler
# ${DEGISKEN} genişletilir, \`backtick\` değişmez kalır
```

---

## Ortam Değişkenleri — Nasıl Akar

```
Host makinesi:
  srcs/.env dosyası
  ├── DOMAIN_NAME=merilhan.42.fr
  ├── DB_ADI=wordpress_db
  └── DB_KULLANICI=wp_manager

  secrets/db_password.txt
  └── "secrets_1906"

  ↓  (docker-compose .env ve secrets'ı okur)

docker-compose.yml:
  services:
    wordpress:
      env_file: .env       ← tüm .env değişkenlerini ortam değişkeni olarak enjekte et
      secrets:
        - db_password      ← dosyayı /run/secrets/db_password'a mount et

  ↓  (container başlar)

WordPress container'ı:
  Ortam değişkenleri:
    DOMAIN_NAME=merilhan.42.fr    ← .env'den
    DB_ADI=wordpress_db            ← .env'den
    DB_KULLANICI=wp_manager        ← .env'den

  Secret dosyaları:
    /run/secrets/db_password      ← "secrets_1906" içeren dosya
    /run/secrets/wp_admin_password
    /run/secrets/wp_user_password

  wp-config.sh bunları okur:
    DB_SIFRESI=$(cat /run/secrets/db_password)
    $DOMAIN_NAME, $DB_ADI, $DB_KULLANICI ortam değişkenlerinden kullanır
```

---

## docker-compose.yml — Satır Satır

```yaml
services:

  mariadb:
    build: requirements/mariadb   # bu Dockerfile dizininden image oluştur
    restart: on-failure:6         # çökerse yeniden başlat, maksimum 6 kez
    env_file: .env                # srcs/.env'deki tüm değişkenleri yükle
    secrets:                      # bu secret dosyalarını /run/secrets/'a mount et
      - db_password
      - db_root_password
    volumes:
      - db_vol:/var/lib/mysql     # isimli volume → container yolu
    networks:
      - dev_net                   # bu iç ağa katıl

  wordpress:
    build: requirements/wordpress
    restart: on-failure:6
    env_file: .env
    secrets:
      - db_password
      - wp_admin_password
      - wp_user_password
    volumes:
      - wp_vol:/var/www/wordpress
    networks:
      - dev_net
    depends_on:                   # wordpress'ten ÖNCE mariadb ve redis başlat
      - mariadb                   # UYARI: sadece "başladı" anlamına gelir, "hazır" değil
      - redis

  nginx:
    build: requirements/nginx
    restart: on-failure:6
    env_file: .env
    ports:
      - "443:443"                 # HOST:CONTAINER — port 443'ü dışarıya aç
    volumes:
      - wp_vol:/var/www/wordpress # WordPress dosyalarını sunmak için lazım
    networks:
      - dev_net
    depends_on:
      - wordpress
      - mariadb
      - adminer
      - portainer
      - static

  ftp:
    build: requirements/ftp
    restart: on-failure
    env_file: .env
    secrets:
      - ftp_password
    ports:
      - "21:21"                   # FTP kontrol portu
      - "21100-21110:21100-21110" # FTP pasif veri portları (aralık)
    volumes:
      - wp_vol:/var/www/wordpress # FTP WordPress dosyalarına erişim sağlar
    networks:
      - dev_net
    depends_on:
      - wordpress

  redis:
    build: requirements/redis
    restart: on-failure
    networks:
      - dev_net                   # port expose yok — sadece iç

  adminer:
    build: requirements/adminer
    restart: on-failure
    networks:
      - dev_net
    depends_on:
      - mariadb

  portainer:
    build: requirements/portainer
    restart: on-failure
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # portainer'a Docker erişimi verir
      - /home/merilhan/data/portainer:/data        # portainer verisini buraya kaydeder
    networks:
      - dev_net

  static:
    build: requirements/static
    restart: on-failure
    networks:
      - dev_net

networks:
  dev_net:                        # özel bridge ağı — tüm container'lar buna katılır
                                  # boş = varsayılanları kullan (bridge sürücüsü, otomatik subnet)

volumes:
  db_vol:
    driver: local                 # yerel sürücü (host makine depolaması)
    driver_opts:
      type: none                  # özel dosya sistemi yok
      device: /home/merilhan/data/mariadb  # veriyi host'ta burada sakla
      o: bind                     # Linux mount seçeneği

  wp_vol:
    driver: local
    driver_opts:
      type: none
      device: /home/merilhan/data/wordpress
      o: bind

secrets:
  db_password:
    file: ../secrets/db_password.txt      # docker-compose.yml'e göre yol
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  ftp_password:
    file: ../secrets/ftp_password.txt
```

---

## Makefile — Açıklaması

```makefile
# Terminal çıktısı için renk kodları
CYAN    = \033[1;36m
PURPLE  = \033[1;35m
GREEN   = \033[1;32m
RED     = \033[1;31m
YELLOW  = \033[1;33m
RESET   = \033[0m

# Yollar ve compose dosyası için değişkenler
WP_DATA         = /home/merilhan/data/wordpress
DB_DATA         = /home/merilhan/data/mariadb
PORTAINER_DATA  = /home/merilhan/data/portainer
COMPOSE         = srcs/docker-compose.yml

# Varsayılan hedef — sadece "make" yazdığında çalışır
all:
	@echo "$(CYAN)=== [ MERILHAN | Inception ] ===$(RESET)"
	@mkdir -p $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)  # veri dizinleri yoksa oluştur
	@docker-compose -f $(COMPOSE) up -d --build         # oluştur ve başlat
	@echo "$(GREEN)=== [ Tamamlandı ] ===$(RESET)"

# Container'ları durdur ve volume'ları kaldır (veri dosyaları kalır)
clean:
	@echo "$(YELLOW)=== [ Container'lar durduruluyor ] ===$(RESET)"
	@docker-compose -f $(COMPOSE) down -v
	@echo "$(GREEN)=== [ Tamamlandı ] ===$(RESET)"

# Tam temizlik — veri dosyalarını ve Docker cache'ini de kaldırır
fclean: clean
	@echo "$(RED)=== [ Tüm veriler siliniyor ] ===$(RESET)"
	@sudo rm -rf $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)  # tüm verileri sil
	@docker system prune -af                               # tüm Docker image'larını/cache'ini kaldır

# Sıfırdan tam yeniden oluşturma
re: fclean all

# make'e bunların gerçek dosyalar olmadığını söyle
.PHONY: all clean fclean re
```

### Komutların Başındaki `@` Neden Var?

Varsayılan olarak make, çalıştırmadan önce her komutu yazdırır. `@` bunu bastırır.

```makefile
# @ olmadan:
mkdir -p /home/merilhan/data   ← make bunu yazdırır
# komut da çalışır

# @ ile:
@mkdir -p /home/merilhan/data  ← make BUNU YAZMIYOR
# komut yine de çalışır
```

### `docker-compose down -v`'deki `-v` Neden Var?

`-v` olmadan: container'ları kaldırır ama Docker'daki isimli volume'ları korur
`-v` ile: isimli volume referanslarını da Docker'dan kaldırır

Not: `-v` ile bile `/home/merilhan/data/`'daki gerçek veri dosyaları SİLİNMEZ. Docker volume metadata'sını kaldırır ama diskteki dosyalar kalır. Sadece `fclean`'deki `rm -rf` gerçek verileri kaldırır.

---

## Container Yaşam Döngüsü

Bir Docker container şu durumlardan geçer:

```
docker create ──→ OLUŞTURULDU
                     │
docker start ───────→ ÇALIŞIYOR ←──── docker restart
                     │           │
docker pause ───────→ DURAKLADI  │
docker unpause ─────→ ÇALIŞIYOR  │
                     │           │
docker stop ────────→ DURDU ────────→ ÇALIŞIYOR (docker start)
docker kill ────────→        │
                     │       │
docker rm ──────────→ SİLİNDİ│
                             │
                    çökme ───→ DURDU (veya yeniden başlatma politikası varsa YENİDEN BAŞLATIYOR)
```

### Container Durumunu Kontrol Et

```bash
# Mevcut durumu gör
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# Örnek çıktı:
# NAMES        STATUS
# srcs-nginx   Up 2 hours         ← çalışıyor
# srcs-wp      Up 2 hours
# srcs-db      Up 2 hours (healthy)
# srcs-redis   Exited (1) 5 minutes ago   ← çöktü
```

---

## Yeniden Başlatma Politikaları

Yeniden başlatma politikaları Docker'a bir container durduğunda veya çöktüğünde ne yapacağını söyler.

```yaml
# docker-compose.yml
services:
  uygulamam:
    restart: no              # hiç yeniden başlatma (varsayılan)
    restart: always          # her zaman yeniden başlat, temiz çıkışta da
    restart: on-failure      # sadece çıkış kodu 0 değilse yeniden başlat (çökme)
    restart: on-failure:6    # çökmede yeniden başlat, maksimum 6 kez
    restart: unless-stopped  # manuel durdurulana kadar her zaman yeniden başlat
```

### Ne Kullandık ve Neden

```yaml
mariadb:
  restart: on-failure:6   # MariaDB çökerse 6 kez dene, sonra vazgeç
                          # yanlış konfigürasyonda sonsuz döngüyü önler

portainer:
  restart: on-failure     # limit yok — portainer her zaman geri gelmeli
```

### Çıkış Kodları

Bir container durduğunda çıkış kodu vardır:
- `0` = temiz çıkış (süreç normal tamamlandı)
- `1` = genel hata
- `2` = komutun yanlış kullanımı
- `137` = SIGKILL ile öldürüldü (docker kill veya OOM killer)
- `143` = SIGTERM ile öldürüldü (docker stop)

`on-failure` sadece çıkış kodu 0 DEĞİLSE yeniden başlatır.

```bash
# Çıkış kodlarını kontrol et
docker ps -a
# STATUS: "Exited (137) 2 minutes ago" → sinyal ile öldürüldü
# STATUS: "Exited (1) 5 minutes ago"   → hata ile çöktü
```

---

## depends_on — Sınırlamaları

`depends_on` Docker Compose'a servisleri belirli sırada başlatmasını söyler. Ama sadece container'ın **başlamasını** bekler — içindeki servisin **hazır** olmasını değil.

```yaml
wordpress:
  depends_on:
    - mariadb   # Docker önce mariadb container'ını başlatır
                # sonra hemen wordpress'i başlatır
                # MariaDB'nin başlatmayı tamamlamasını BEKLEMEZ
```

Bu yüzden WordPress entrypoint script'i yeniden deneme döngüsü kullanır:

```sh
# MariaDB başlıyor ama henüz hazır olmayabilir
# wp core install bağlanmaya çalışır — başarısız olursa bekle ve tekrar dene
until wp core install ...; do
    echo "MariaDB henüz hazır değil, bekleniyor..."
    sleep 2
done
```

### Koşullu depends_on (Daha Gelişmiş)

Bir servise `healthcheck` eklerseniz `condition: service_healthy` kullanabilirsiniz:

```yaml
services:
  mariadb:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  wordpress:
    depends_on:
      mariadb:
        condition: service_healthy   # healthcheck geçene kadar bekle
```

Projeyi basit tutmak için bu yaklaşımı kullanmadık ama "doğru" çözüm budur.

---

## Health Check (Sağlık Kontrolü)

Health check, Docker'ın container'ın düzgün çalışıp çalışmadığını kontrol etmek için periyodik olarak çalıştırdığı bir komuttur. Yeterince başarısız olursa container "sağlıksız" olarak işaretlenir.

```dockerfile
# Dockerfile'da:
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD mysqladmin ping -h localhost || exit 1

# Seçenekler:
# --interval   ne sıklıkta kontrol et (varsayılan 30s)
# --timeout    kontrolün bitmesi için ne kadar bekle (varsayılan 30s)
# --retries    sağlıksız işaretlemeden önce kaç başarısızlık (varsayılan 3)
# --start-period  kontroller başlamadan önce başlangıç tolerans süresi
```

```yaml
# docker-compose.yml'de:
services:
  mariadb:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

```bash
# Sağlık durumunu gör
docker ps
# STATUS sütunu: "Up 2 minutes (healthy)" veya "Up 2 minutes (unhealthy)"

# Health check geçmişini gör
docker inspect --format='{{json .State.Health}}' container-adı | python3 -m json.tool
```

---

## /var/run/docker.sock Nedir

`/var/run/docker.sock` bir Unix soket dosyasıdır. Docker daemon'u (host'ta çalışan Docker motoru) ile iletişim kurmanın yoludur.

`docker ps` veya `docker build` çalıştırdığında, Docker istemcin komutları bu soket üzerinden Docker daemon'una gönderir. Daemon asıl işi yapar.

```
docker CLI  ──→  /var/run/docker.sock  ──→  Docker daemon  ──→  container'lar
```

Portainer bu soketi kendi container'ına mount eder:

```yaml
portainer:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

Bu Portainer'a Docker daemon'u ile doğrudan konuşma yeteneği verir — container'ları listele, log'ları oku, servisleri başlat/durdur. Portainer esasen Docker API'sinin web arayüzü sarıcısıdır.

**Güvenlik notu:** Docker soketini mount etmek container'a Docker üzerinde tam kontrol verir. O container içindeki bir süreç yeni container'lar başlatabilir, volume'ları silebilir, Docker'ın yapabildiği her şeyi yapabilir. Bunu sadece güvendiğin servislere ver.

---

## HTTP Durum Kodları — Debug İçin

Bir şeyler yanlış gittiğinde HTTP durum kodu sorunun nerede olduğunu söyler.

### 2xx — Başarı

| Kod | Anlam | Ne zaman görürsün |
|---|---|---|
| `200 OK` | Her şey çalıştı | Normal sayfa yükleme |
| `201 Created` | Kaynak oluşturuldu | API POST isteği |
| `204 No Content` | Başarı, içerik yok | DELETE istekleri |

### 3xx — Yönlendirmeler

| Kod | Anlam | Bu projede |
|---|---|---|
| `301 Kalıcı Taşındı` | URL sonsuza dek değişti | WordPress HTTPS'e taşındı |
| `302 Bulundu` | Geçici yönlendirme | WordPress giriş, wp-admin |
| `304 Değiştirilmedi` | Önbelleğe alınan sürümü kullan | Tarayıcı önbelleği çalışıyor |

**302 döngüsü** = Veritabanındaki WordPress `siteurl` `http://` ama NGINX `https://` sunuyor → sonsuz yönlendirme. Düzeltme: veritabanındaki `siteurl` ve `home` seçeneklerini `https://` içerecek şekilde güncelle.

### 4xx — İstemci Hataları

| Kod | Anlam | Yaygın nedeni |
|---|---|---|
| `400 Geçersiz İstek` | Geçersiz istek | Hatalı URL veya başlıklar |
| `401 Yetkisiz` | Giriş gerekli | Kimlik doğrulama eksik |
| `403 Yasak` | İzin yok | Dosya izinleri yanlış (`chmod`) |
| `404 Bulunamadı` | Sayfa yok | Yanlış URL, eksik dosya |
| `413 Yük Çok Büyük` | Yükleme çok büyük | WordPress yükleme limiti |

### 5xx — Sunucu Hataları

| Kod | Anlam | Bu projede yaygın nedeni |
|---|---|---|
| `500 İç Sunucu Hatası` | PHP çöktü | PHP sözdizimi hatası, yanlış konfigürasyon |
| `502 Kötü Ağ Geçidi` | Upstream hatası | WordPress/PHP-FPM container'ı çöktü |
| `503 Servis Kullanılamıyor` | Sunucu aşırı yüklü | Çok fazla istek veya container başlıyor |
| `504 Ağ Geçidi Zaman Aşımı` | Upstream çok yavaş | PHP-FPM çok uzun sürüyor |

```bash
# Hangi durum kodunu aldığını kontrol et
curl -sk -o /dev/null -w "%{http_code}" https://merilhan.42.fr
# 200 yazmalı

# Tam yanıt başlıklarını gör
curl -Ik https://merilhan.42.fr

# Yönlendirmeleri takip et ve her adımı göster
curl -Lk -v https://merilhan.42.fr 2>&1 | grep -E "^[<>]"
```

---

## Multi-Stage Build

Multi-stage build'ler bir Dockerfile'da birden fazla `FROM` komutu kullanmana izin verir. Her aşama adlandırılabilir. Önceki aşamalardan sonrakilere dosya kopyalayabilirsin.

Bu, bir şeyleri derlemek için araçlara ihtiyaç duyduğunda ama bu araçların son image'da olmasını istemediğinde faydalıdır.

```dockerfile
# Aşama 1 — derleme aşaması (derleme araçları var, atılacak)
FROM debian:bookworm AS derleyici
RUN apt-get update && apt-get install -y build-essential
COPY src/ /src/
RUN cd /src && make

# Aşama 2 — son image (sadece derlenmiş binary var)
FROM debian:bookworm
COPY --from=derleyici /src/uygulamam /usr/local/bin/uygulamam
ENTRYPOINT ["uygulamam"]
```

Son image `build-essential` veya kaynak kod içermez — sadece derlenmiş binary. Çok daha küçük ve güvenli.

Bu proje multi-stage build kullanmıyor çünkü tüm servisler derleme gerektirmeyen yorumlanan diller kullanıyor (PHP, shell script'leri). Ama Go, C veya Rust projeleri için çok faydalı.

---

## Container İçinde Faydalı Linux Komutları

`docker exec -it container sh` yaptığında bu komutlar debug etmene yardımcı olur:

```bash
# Dosya sistemi
ls -la /var/www/wordpress     # dosyaları izinleriyle listele
find / -name "wp-config.php"  # dosya bul
cat /etc/nginx/nginx.conf     # dosyayı oku
du -sh /var/www/wordpress     # dizinin disk kullanımı

# Süreçler
ps aux                        # tüm çalışan süreçleri listele
ps -p 1 -o comm=              # PID 1 ne?
top                           # canlı süreç izleme (kuruluysa)

# Ağ
ip addr                       # ağ arayüzlerini ve IP'leri göster
ip route                      # yönlendirme tablosunu göster
cat /etc/resolv.conf          # DNS sunucusunu göster (Docker'da 127.0.0.11 olmalı)
cat /etc/hosts                # hosts dosyasını göster

# Ağ bağlantısını test et
ping mariadb                  # mariadb'ye ulaşabiliyor muyuz? (ping kuruluysa)
nc -zv mariadb 3306           # mariadb port 3306'ya TCP bağlantısını test et
nc -zv redis 6379             # redis bağlantısını test et

# Ortam
env                           # tüm ortam değişkenlerini göster
echo $DB_ADI                  # bir değişkeni göster
cat /run/secrets/db_password  # bir secret'ı oku

# Log'lar
cat /var/log/nginx/error.log  # nginx hata logu
cat /var/log/mysql/error.log  # mariadb hata logu

# PHP
php -v                        # PHP sürümü
php -m                        # kurulu PHP modülleri
php -i | grep redis           # redis uzantısının yüklü olup olmadığını kontrol et

# İzinler
id                            # mevcut kullanıcı ve gruplar
whoami                        # mevcut kullanıcı adı
stat /var/www/wordpress       # ayrıntılı izinler ve sahiplik
```

---

## Bu Proje — Mimari

### Servisler ve Bağlantıları

```
İnternet
    │
    │ HTTPS port 443
    ▼
┌──────────────────────────────────────────────────────┐
│  NGINX container                                      │
│  - SSL/TLS işler                                     │
│  - İstekleri yönlendirir:                           │
│    /          → WordPress (FastCGI port 9000)        │
│    /adminer/  → Adminer (HTTP port 8080)             │
│    /portainer/→ Portainer (HTTP port 9000)           │
│    /portfolio/→ Statik site (HTTP port 80)           │
└──────────────────────────────────────────────────────┘
    │ (iç ağ: dev_net)
    ├─────────────────┬──────────────┬──────────────┐
    ▼                 ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│WordPress │   │ Adminer  │   │Portainer │   │  Statik  │
│PHP-FPM   │   │  :8080   │   │  :9000   │   │ NGINX:80 │
│  :9000   │   └────┬─────┘   └──────────┘   └──────────┘
└────┬─────┘        │
     │              │ port 3306
     ▼              ▼
┌──────────────────────┐
│       MariaDB        │
│        :3306         │
└──────────────────────┘
     ▲
     │ port 6379
┌──────────┐
│  Redis   │ ← WordPress nesne önbelleği
│  :6379   │
└──────────┘

FTP (NGINX üzerinden değil, ayrı port):
port 21 + 21100-21110 → FTP sunucusu → WordPress volume
```

---

## Portlar ve Servisler

### Dış Portlar (dünyaya açık)

| Port | Protokol | Container | Amaç |
|---|---|---|---|
| `443` | HTTPS | nginx | Tüm web trafiği — ana giriş noktası |
| `21` | FTP | ftp | FTP kontrol bağlantısı |
| `21100-21110` | FTP pasif | ftp | Veri aktarımı |

### İç Portlar (sadece Docker ağı içinde)

| Port | Container | Kim Bağlanır |
|---|---|---|
| `9000` | wordpress (PHP-FPM) | nginx |
| `3306` | mariadb | wordpress, adminer |
| `6379` | redis | wordpress |
| `80` | static | nginx |
| `8080` | adminer | nginx |
| `9000` | portainer | nginx |

---

## Veri Depolama

Tüm kalıcı veri host makinede `/home/merilhan/data/` altında:

```
/home/merilhan/data/
├── wordpress/          ← WordPress dosyaları
│   ├── wp-config.php   ← ilk açılışta oluşturulur
│   ├── wp-content/     ← temalar, eklentiler, yüklemeler
│   │   ├── themes/
│   │   ├── plugins/
│   │   └── uploads/
│   ├── wp-admin/
│   └── wp-includes/
│
├── mariadb/            ← MariaDB veritabanı dosyaları
│   ├── wordpress_db/   ← WordPress veritabanı
│   ├── mysql/          ← MariaDB sistem tabloları
│   └── ibdata1         ← InnoDB paylaşımlı tablo alanı
│
└── portainer/          ← Portainer ayarları ve verisi
    └── portainer.db
```

### Her Komutta Verilere Ne Olur

```bash
make clean
# → docker-compose down -v
# → Container'lar durur
# → Docker volume referanslarını kaldırır (srcs_wp_vol, srcs_db_vol)
# → /home/merilhan/data/ ALTINDA VERİ DOSYALARI KALIR
# → Sonraki "make" mevcut dosyaları bulur → WordPress'i YENİDEN KURMAZ

make fclean
# → önce make clean çalışır
# → sudo rm -rf /home/merilhan/data/wordpress
# → sudo rm -rf /home/merilhan/data/mariadb
# → sudo rm -rf /home/merilhan/data/portainer
# → docker system prune -af (tüm image'ları kaldırır)
# → VERİ GİDİ
# → Sonraki "make" = tamamen sıfırdan kurulum
```

---

## Projeyi Yönetmek

### Her Şeyi Başlat

```bash
make
```

### Durumu Kontrol Et

```bash
docker-compose -f srcs/docker-compose.yml ps
# Tüm container'lar "Up" göstermeli
```

### Log'ları Gör

```bash
# Tüm servisler
docker-compose -f srcs/docker-compose.yml logs -f

# Tek servis
docker-compose -f srcs/docker-compose.yml logs -f wordpress
docker-compose -f srcs/docker-compose.yml logs -f mariadb
docker-compose -f srcs/docker-compose.yml logs -f nginx
```

### Debug İçin Container'a Gir

```bash
# WordPress container'ına gir
docker exec -it $(docker ps -q -f name=wordpress) sh

# MariaDB container'ına gir
docker exec -it $(docker ps -q -f name=mariadb) sh

# NGINX konfigürasyonunu test et
docker exec $(docker ps -q -f name=nginx) nginx -t

# Redis'i kontrol et
docker exec $(docker ps -q -f name=redis) redis-cli ping
```

---

## Güvenlik En İyi Pratikleri

### Dockerfile'a Şifre Koyma

```dockerfile
# KÖTÜ — şifre image katmanlarında sonsuza dek görünür
RUN mysql -u root -pbenimsifrem -e "CREATE DATABASE mydb"

# İYİ — çalışma zamanında secret'tan oku
RUN mysql -u root -p$(cat /run/secrets/db_root_password) -e "CREATE DATABASE mydb"
```

### Container İçinde Root Olma

```dockerfile
# KÖTÜ — her şey root olarak çalışır
RUN apt-get install -y nginx
CMD ["nginx"]

# İYİ — kullanıcı oluştur ve ona geç
RUN useradd -r -s /bin/false nginx-kullanicisi
USER nginx-kullanicisi
CMD ["nginx"]
```

### Image'ları Küçük Tut

```dockerfile
# Fazladan paketlerden kaçınmak için --no-install-recommends kullan
RUN apt-get install -y --no-install-recommends nginx

# Aynı katmanda apt cache'i temizle
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
```

### Belirli Sürüm Etiketleri Kullan

```dockerfile
# KÖTÜ — "latest" değişebilir ve şeyleri bozabilir
FROM nginx:latest

# İYİ — belirli sürüme sabitle
FROM debian:bookworm
```

### Secret'ları Asla Git'e Commit Etme

```bash
# .gitignore şunları içermeli:
secrets/
srcs/.env

# Gizli bir şeyin takip edilmediğini doğrula
git status
git ls-files | grep -E "(\.env|password|secret|key)"
```

### Minimal Port Expose

```yaml
# KÖTÜ — MariaDB'yi internete açmak
mariadb:
  ports:
    - "3306:3306"  # herkes bağlanmayı deneyebilir

# İYİ — port expose yok, sadece iç ağ
mariadb:
  networks:
    - dev_net     # sadece diğer container'lar ulaşabilir
```

---

## Sorun Giderme

### Container Sürekli Yeniden Başlıyor

```bash
# Neden başarısız olduğunu gör
docker logs --tail 50 container-adı

# Çıkış kodunu gör
docker ps -a
# STATUS sütunu: "Exited (1)" = çöktü, "Exited (0)" = temiz çıkış
```

### Siteye Bağlanamıyorum

```bash
# Port 443'ün dinleyip dinlemediğini kontrol et
ss -tlnp | grep 443

# NGINX çalışıyor mu?
docker ps | grep nginx

# NGINX log'larını kontrol et
docker-compose -f srcs/docker-compose.yml logs nginx

# NGINX konfigürasyonunu test et
docker exec $(docker ps -q -f name=nginx) nginx -t

# curl ile bağlantıyı test et (SSL uyarılarını yok say)
curl -vk https://merilhan.42.fr
```

### WordPress "Veritabanı Bağlantısı Kurulamıyor" Hatası

```bash
# 1. MariaDB çalışıyor mu?
docker ps | grep mariadb

# 2. MariaDB log'larını kontrol et
docker-compose -f srcs/docker-compose.yml logs mariadb

# 3. Secret'ların mount edildiğini kontrol et
docker exec $(docker ps -q -f name=wordpress) cat /run/secrets/db_password

# 4. Manuel olarak bağlanmayı dene
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db
```

### WordPress 302 Döngüsü

```bash
# Veritabanındaki siteurl'yi kontrol et
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db \
  -e "SELECT option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

# https://merilhan.42.fr göstermeli
# http:// gösteriyorsa sorun bu
# Düzeltme:
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db \
  -e "UPDATE wp_options SET option_value='https://merilhan.42.fr' WHERE option_name IN ('siteurl', 'home');"
```

### Port Zaten Kullanımda

```bash
# 443 portunu kimin kullandığını bul
sudo lsof -i :443
sudo ss -tlnp | grep 443

# Kullanan süreci öldür
sudo kill -9 PID_NUMARASI
```

### Build Başarısız — apt-get Hataları

```bash
# Build cache'i temizle ve yeniden oluştur
docker-compose -f srcs/docker-compose.yml build --no-cache

# Veya belirli bir servis için
docker-compose -f srcs/docker-compose.yml build --no-cache wordpress
```

### "Cihazda Yer Kalmadı"

```bash
# Disk kullanımını gör
df -h

# Docker'ın disk kullanımını gör
docker system df

# Docker kaynaklarını temizle
docker system prune -a
```

### Portainer Zaman Aşımı Sayfası Gösteriyor

```bash
docker restart $(docker ps -q -f name=portainer)
# Sonra hızlıca https://merilhan.42.fr/portainer/ adresine git ve admin hesabı oluştur
```

### FTP Bağlantı Reddedildi

```bash
# FTP container'ını kontrol et
docker ps | grep ftp
docker-compose -f srcs/docker-compose.yml logs ftp

# curl ile FTP'yi test et
curl -v ftp://merilhan.42.fr --user ftpuser:$(cat secrets/ftp_password.txt)
```

---

## Hızlı Başvuru Kartı

```bash
# ── BU PROJE ─────────────────────────────────────────
make                     # her şeyi başlat
make re                  # tam temiz yeniden oluştur
make clean               # container'ları durdur (veri kalır)
make fclean              # her şeyi sil

# ── DURUM ────────────────────────────────────────────
docker ps                # çalışan container'lar
docker ps -a             # tüm container'lar
docker stats             # CPU/bellek kullanımı
docker-compose -f srcs/docker-compose.yml ps

# ── LOG'LAR ──────────────────────────────────────────
docker-compose -f srcs/docker-compose.yml logs -f
docker-compose -f srcs/docker-compose.yml logs -f wordpress
docker-compose -f srcs/docker-compose.yml logs -f nginx
docker logs container-adı

# ── DEBUG ─────────────────────────────────────────────
docker exec -it $(docker ps -q -f name=wordpress) sh
docker exec -it $(docker ps -q -f name=mariadb) sh
docker exec -it $(docker ps -q -f name=nginx) sh
docker exec $(docker ps -q -f name=nginx) nginx -t
docker exec $(docker ps -q -f name=redis) redis-cli ping

# ── VOLUME'LAR ───────────────────────────────────────
docker volume ls
docker volume inspect srcs_wp_vol
ls /home/merilhan/data/wordpress/
ls /home/merilhan/data/mariadb/

# ── AĞLAR ────────────────────────────────────────────
docker network ls
docker network inspect srcs_dev_net

# ── IMAGE'LAR ────────────────────────────────────────
docker images
docker image prune -a
docker-compose -f srcs/docker-compose.yml build --no-cache

# ── TEMİZLİK ─────────────────────────────────────────
docker system prune -a --volumes
docker container prune
docker volume prune
docker image prune -a

# ── VERİTABANI ───────────────────────────────────────
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db

# ── REDİS ────────────────────────────────────────────
docker exec -it $(docker ps -q -f name=redis) redis-cli
docker exec $(docker ps -q -f name=redis) redis-cli info stats

# ── WP-CLI ───────────────────────────────────────────
docker exec -it $(docker ps -q -f name=wordpress) \
  wp user list --allow-root
docker exec -it $(docker ps -q -f name=wordpress) \
  wp redis status --allow-root
```