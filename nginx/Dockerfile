# Dockerfile-nginx-geoip
FROM nginx:1.28.0

# 1. Install build‑deps & the MaxMind DB library
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git build-essential libmaxminddb-dev libpcre3-dev zlib1g-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Fetch the geoip2 module source
RUN git clone --depth 1 \
      https://github.com/leev/ngx_http_geoip2_module.git \
      /tmp/ngx_http_geoip2_module

# 3. Download matching Nginx source, compile the dynamic module
RUN NGINX_VER="$(nginx -v 2>&1 | cut -d/ -f2)" && \
    wget http://nginx.org/download/nginx-$NGINX_VER.tar.gz -O - | tar zx -C /tmp && \
    cd /tmp/nginx-$NGINX_VER && \
    ./configure --with-compat \
      --add-dynamic-module=/tmp/ngx_http_geoip2_module && \
    make modules && \
    cp objs/ngx_http_geoip2_module.so /etc/nginx/modules && \
    rm -rf /tmp/nginx-* /tmp/ngx_http_geoip2_module

# 4. Copy in your configs (which must `load_module` at top)
COPY nginx/nginx.conf      /etc/nginx/nginx.conf
COPY nginx/conf.d/         /etc/nginx/conf.d/

# 5. Expose ports and default workdir
EXPOSE 80 443