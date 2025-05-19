# nginx/Dockerfile
ARG NGINX_VERSION=1.28.0
FROM nginx:${NGINX_VERSION}

# install build tools and GeoIP2 library
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git build-essential \
      libmaxminddb0 libmaxminddb-dev \
      libpcre3-dev zlib1g-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# fetch the GeoIP2 module source
RUN git clone \
      https://github.com/leev/ngx_http_geoip2_module.git \
      /tmp/ngx_http_geoip2_module

# download matching nginx source, compile just the geoip2 module
RUN cd /tmp \
 && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
 && tar zxvf nginx-${NGINX_VERSION}.tar.gz \
 && cd nginx-${NGINX_VERSION} \
 && ./configure --with-compat \
                 --add-dynamic-module=/tmp/ngx_http_geoip2_module \
 && make modules \
 && cp objs/ngx_http_geoip2_module.so /etc/nginx/modules/

# clean up
RUN rm -rf /tmp/nginx-${NGINX_VERSION} /tmp/ngx_http_geoip2_module

# load the module and set up config
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/    /etc/nginx/conf.d/