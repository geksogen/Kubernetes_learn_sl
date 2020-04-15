1) Рассказываем про NS, показываем ls -l /proc/$$/ns ; echo $$ ; ps aux | grep номер_пида

2) Показываем на 1 консоли lnls. Рассказываем про unshare, показываем ее help

3) В другой консоли делаем unshare -u bash && ls -l /proc/$$/ns в обоих

4) hostname на обоих, на второй hostname dockertest; показываем что на первой все по старому

5) Снова показываем на 1 консоли lnls, видим новый NS

6) exit на 2 консоли, делаем там ps aux, ip a и делаем unshare --pid --net --fork --mount-proc 

/bin/bash

7) Снова делаем ps aux, ip a. делаем exit

8) Ставим yum install -y yum-utils

9) yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

10) yum install docker-ce docker-ce-cli containerd.io

11) systemctl status docker && systemctl start docker

12) docker ps

13)

docker build -t test  -<<EOF

FROM alpine
ENTRYPOINT ["ping"]

CMD ["8.8.8.8"]

EOF


14) docker run --name test --rm -d test

15) lsns

16) docker exec -it test /bin/sh && ps aux && ip a && exit

17) nsenter -t номер_пида --pid --net --mount --ipc --uts sh

18)

docker build -t test_resource  -<<EOF

FROM alpine
ENTRYPOINT ["sleep"]

CMD ["3600"]

EOF

19) docker run --name test_resource --memory=100m --cpus=".2" --rm -d test_resource

20) systemd-cgls, находим SHA контейнера, идем в /sys/fs/cgroup/memory/docker/сша_контейнера

21) cat memory.limit_in_bytes | awk '{$1=$1/1024/1024; print}'

22) cat tasks

23) Идем в /sys/fs/cgroup/cpu,cpuacct/docker/сша_контейнера

24) cat cpu.cfs_quota_us

25) yum install libcgroup-tools -y

26) cgget docker/сша_контейнера

27) cgget -r memory.limit_in_bytes docker/сша_контейнера

ТЕСТ_ЗАДАНИЕ: запустить контейнер с именем test_limit из образа test_resource с ограничением в 200 

мегабайт ОЗУ и 0,5 CPU. Получить через утилиту cgget значения memory.limit_in_bytes и 

cpu.cfs_quota_us этого контейнера. Они должны быть равны 209715200 и 50000 соответственно. 

28) Останавливаем запущенные ранее контейнеры docker stop $(docker ps -q)

--------------

1) Рассказываем про тома докера. Далее делаем

docker build -t redis_1  -<<EOF

FROM redis
VOLUME /data

EOF

2) docker run --rm -d --name redis_1 redis_1 && docker volume ls

3) docker stop $(docker ps -q)

4) docker run --rm --name redis_1 -d --mount type=volume,source=data,destination=/data redis_1

5) docker volume ls && ll /var/lib/docker/volumes/data/_data/

6) docker exec -it redis_1 bash

7) redis-cli && set mykey foobar && get mykey && save && exit && ls && exit

8) ls /var/lib/docker/volumes/data/_data/

9) docker stop redis_1 && docker volume ls

10) docker run --rm --name redis_1 -d --mount type=volume,source=data,destination=/data redis_1

11) docker exec -it redis_1 bash && redis-cli && get mykey && exit && exit

ТЕСТ_ЗАДАНИЕ: Запустите контейнер с именем redis_2 из образа redis_1 который будет использовать тот 

же самый volume. Для проверки что все получилось зайдите внутрь контейнера redis_2 и в redis_cli 

выполните "get mykey". Если вы все сделали верно, то отдастся значение foobar.

14) docker stop $(docker ps -q) && docker volume ls

15) docker volume inspect data && docker volume rm data

------

1) yum install docker-compose -y && docker-compose version

2) cd /srv && git clone git@gitlab.slurm.io:school/slurm.git

3) cd /srv/slurm/1.Docker/compose

4) Показываем содержимое (кроме _dz)

5) docker-compose up -d , делаем curl 127.0.0.1 пару раз; смотрим docker volume ls

6) docker-compose down; docker volume rm сша_вольюма; смотрим docker-compose.yml_vol

7) docker-compose -f docker-compose.yml_vol up -d 

8) делаем curl 127.0.0.1 пару раз; docker-compose down

9) docker-compose -f docker-compose.yml_vol up -d; делаем curl 127.0.0.1

10) docker-compose down

ТЕСТ_ЗАДАНИЕ: Запустить это же приложение, но с healthcheck'ом сервиса redis'а через команду redis-

cli ping, а старт сервиса web сделать зависимым от здоровья сервиса redis. Также ограничить через 

compose файл сервису redis RAM до 500 МБ и CPU до 0,5. Проверить что все получилось можно сделав 

после запуска и получив значения:

docker inspect compose_redis_1 | grep "Memory\|NanoCpus"
            "Memory": 524288000,
            "NanoCpus": 500000000,

либо использовав утилиту cgget.