FROM fedora

LABEL 'maintainer=Furutanian <furutanian@gmail.com>'

ARG http_proxy
ARG https_proxy

RUN set -x \
	&& dnf install -y \
		hostname \
		httpd \
		mod_ssl \
		procps-ng \
		net-tools \
	&& rm -rf /var/cache/dnf/* \
	&& dnf clean all

RUN systemctl enable httpd
EXPOSE 80 443

# Dockerfile 中の設定スクリプトを抽出するスクリプトを出力、実行
COPY Dockerfile .
RUN echo $'\
cat Dockerfile | sed -n \'/^##__BEGIN0/,/^##__END0/p\' | sed \'s/^#//\' > startup.sh\n\
' > extract.sh && bash extract.sh

# docker-compose up の最後に実行される設定スクリプト
##__BEGIN0__startup.sh__
#
#	ln -sv /root/rproxy4kube/rproxy.conf /etc/httpd/conf.d/
#	ln -sv /root/rproxy4kube/dot.digest_pw /var/www/.digest_pw
#
##__END0__startup.sh__

