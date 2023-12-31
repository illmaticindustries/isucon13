deploy:
	ssh isucon13-1 " \
		cd /home/isucon; \
		git checkout .; \
		git fetch; \
		git checkout $(BRANCH); \
		git reset --hard origin/$(BRANCH)"

build:
	ssh isucon13-1 " \
		cd /home/isucon/webapp/go; \
		/home/isucon/local/golang/bin/go build -o isupipe"

go-deploy:
	scp ./webapp/go/isupipe isucon13-1:/home/isucon/webapp/go/

go-deploy-dir:
	scp -r ./webapp/go isucon13-1:/home/isucon/webapp/

restart:
	ssh isucon13-1 "sudo systemctl restart isupipe-go.service"

mysql-deploy:
	ssh isucon13-1 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf
	ssh isucon13-2 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf
	ssh isucon13-3 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf

mysql-rotate:
	ssh isucon13-1 "sudo rm -f /var/log/mysql/mysql-slow.log"
	ssh isucon13-2 "sudo rm -f /var/log/mysql/mysql-slow.log"
	ssh isucon13-3 "sudo rm -f /var/log/mysql/mysql-slow.log"

mysql-restart:
	ssh isucon13-1 "sudo systemctl restart mysql.service"
	ssh isucon13-2 "sudo systemctl restart mysql.service"
	ssh isucon13-3 "sudo systemctl restart mysql.service"

nginx-deploy:
	ssh isucon13-1 "sudo dd of=/etc/nginx/nginx.conf" < ./etc/nginx/nginx.conf
	ssh isucon13-1 "sudo dd of=/etc/nginx/sites-enabled/isupipe.conf" < ./etc/nginx/sites-enabled/isupipe.conf

nginx-rotate:
	ssh isucon13-1 "sudo rm -f /var/log/nginx/access.log"

nginx-reload:
	ssh isucon13-1 "sudo systemctl reload nginx.service"

nginx-restart:
	ssh isucon13-1 "sudo systemctl restart nginx.service"

.PHONY: bench
bench:
	ssh isucon13-bench " \
		cd /home/isucon/bench; \
		./bench -target-addr 172.31.41.209:443"

pt-query-digest-1:
	ssh isucon13-1 "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

pt-query-digest-2:
	ssh isucon13-2 "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

pt-query-digest-3:
	ssh isucon13-3 "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

ALPSORT=sum
# /api/livestream/7508/report
# /api/user/mikakosasaki0/icon
# /api/livestream/7515/ngwords
# /api/livestream/7508/reaction
# /api/livestream/7510/livecomment/1004/report
# /api/livestream/7497/exit
# /api/livestream/7497/enter
# /api/user/jtakahashi0/theme
# /api/livestream/7510/livecomment
# /api/livestream/7497
# /api/user/suzukitsubasa0/statistics
# /api/livestream/search?tag=%E6%98%A0%E7%94%BB%E3%83%AC%E3%83%93%E3%83%A5%E3%83%BC
ALPM=/api/livestream/[0-9]+/report,/api/user/[0-9a-zA-Z]+/icon,/api/livestream/[0-9]+/ngwords,/api/livestream/[0-9]+/reaction,/api/livestream/[0-9]+/livecomment/[0-9]+/report,/api/livestream/[0-9]+/exit,/api/livestream/[0-9]+/enter,/api/user/[0-9a-zA-Z]+/theme,/api/livestream/[0-9]+/livecomment,/api/livestream/[0-9]+/moderate,/api/user/[0-9a-zA-Z]+/statistics,/api/livestream/search

OUTFORMAT=count,method,uri,min,max,sum,avg,p99

alp:
	ssh isucon13-1 "sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q"

.PHONY: pprof
pprof:
	ssh isucon13-1 " \
		/home/isucon/local/golang/bin/go tool pprof -seconds=120 /home/isucon/webapp/go/isupipe http://localhost:6060/debug/pprof/profile"

pprof-show:
	$(eval latest := $(shell ssh isucon13-1 "ls -rt ~/pprof/ | tail -n 1"))
	scp isucon13-1:~/pprof/$(latest) ./pprof
	go tool pprof -http=":1080" ./pprof/$(latest)

pprof-kill:
	ssh isucon13-1 "pgrep -f 'pprof' | xargs kill;"
