### Перед стартом практики

1) Заходим **по SSH** на sbox таким образом `ssh sXXXXXX@sbox.slurm.io`

Где `sXXXXXX` - это номер вашего имени пользователя. Учетные данные доступны в [личном кабинете](https://edu.slurm.io/profile)

2) Подключившись к sbox, далее подключаемся к своей площадке `ssh docker.sXXXXXX`

3) Делаем `sudo -s`, так как будем работать под рутом

4) Таким образом нужно открыть **две консоли** c подключением к `docker.sXXXXXX`

### Закрепляем тему namespace / cgroups

1) Смотрим PID своей оболочки *bash* и его *namespaces*:

```
ls -l /proc/$$/ns
echo $$
ps aux | grep номер_пида
```
 
2) Смотрим какие текущие *namespaces* есть в системе через `lsln`. Знакомимся с утилитой `unshare`

```
lsln
unshare --help
```

3) **В консоли №2** отделяем процесс *bash* в отдельный *UTS namespace* и смотрим что он действительно изменился 

```
unshare -u bash
ls -l /proc/$$/ns <--- в обоих консолях
```

4) Изменим hostname в **консоли №2** , и проверим что в консоли №1 он не поменялся:

```
hostname testhost <--- в консоли №2
hostname <--- в консоли №2

hostname <--- в консоли №1
```

5) В **консоли №1** выполняем команду `lsln` и видим новый *namespace* созданный нами с процессом *bash*:

6) Выходим из запущенной ранее оболочки bash на **консоли №2**. Смотрим текущие процессы **консоли №2** и сетевое окружение

```
exit
ps aux
ip a 
```

7) В **консоли №2** поместим теперь процесс *bash* в несколько *namespace'ов*:

`unshare --pid --net --fork --mount-proc /bin/bash`

8) Снова смотрим в **консоли №2** процессы и сетевое окружение. Видим что наш *bash* изолирован. Затем выходим из запущенного *bash*:

```
ps aux
ip a
exit
```

9) Устанавливаем *Docker*:

```
yum install -y yum-utils

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io

systemctl enable --now docker && systemctl status docker
```

10) Убеждаемся что все ОК. Посмотрим запущеные контейнеры. Так как мы ничего не запускали, команда выведет пустую табличку:

`docker ps`

11) Соберем наш первый образ на базе *Alpine*, который будет пинговать *8.8.8.8*:

```
docker build -t test  -<<EOF

FROM alpine
ENTRYPOINT ["ping"]

CMD ["8.8.8.8"]

EOF
```

12) Запустим контейнер из собранного образа: `docker run --name test --rm -d test`

13) Посмотрим какие *namespace* создал *Docker*, запомним *PID* процесса нашего контейнера:

`lsns`

14) Войдем внутрь контейнера, проверим запущенные процессы и сетевое окружение. Затем выйдем:

```
docker exec -it test /bin/sh
ps aux
ip a
exit
```

15) Теперь воспользуемся утилитой *nsenter* чтобы подключиться к *namespace'ам* этого контейнера. Используем номер *PID* этого контейнера:

`nsenter -t номер_пида --pid --net --mount --ipc --uts sh`

16) Убедимся что мы видим тоже самое окружение как если бы использовали *docker exec*:

```
ps aux
ip a
exit
```

17) Соберем еще один образ:

```
docker build -t test_resource  -<<EOF

FROM alpine
ENTRYPOINT ["sleep"]

CMD ["3600"]

EOF
```

18) Запустим контейнер из этого образа, но наложим на него ограничения по ресурсам в *100Мб ОЗУ* и *0,2 CPU*:

`docker run --name test_resource --memory=100m --cpus=".2" --rm -d test_resource`

19) Воспользуемся утилитой `systemd-cgls` чтобы посмотреть текущие *cgroups*. Находим там *SHA* нашего контейнера и идем в папку его *cgroup* по памяти:

```
systemd-cgls <--- находим тут SHA нашего контейнера

cd /sys/fs/cgroup/memory/docker/SHA_контейнера
```

20) Убеждаемся что в cgroup контейнера действительно есть заданные ограничения:

`cat memory.limit_in_bytes | awk '{$1=$1/1024/1024; print}'`

21) Убеждаемся что наш процесс действительно в этой *cgroup*:

`cat tasks`

22) Проверим ограничения по *CPU*: 

`cd /sys/fs/cgroup/cpu/docker/SHA_контейнера`

23) Смотрим что ограничения есть:

`cat cpu.cfs_quota_us`

24) Ставим *libcgroup* 

`yum install libcgroup-tools -y`

25) Посмотрим *cgroups* нашего контейнера через утилиту от *libcgroup*:

`cgget docker/SHA_контейнера`

26) Через передачу ключа `-r` можно посмотреть конкретный параметр *cgroup'ы*:

`cgget -r memory.limit_in_bytes docker/SHA_контейнера`

**САМОСТОЯТЕЛЬНАЯ РАБОТА:** 

- Запустить контейнер с именем test_limit из образа test_resource с ограничением в 200 Мб ОЗУ и 0,5 CPU 
- Получить через утилиту cgget значения memory.limit_in_bytes и cpu.cfs_quota_us этого контейнера
- Они должны быть равны 209715200 и 50000 соответственно. 

27) Останавливаем запущенные ранее контейнеры `docker stop $(docker ps -q)` и можно закрыть **консоль №2**

--------------

### Закрепляем тему Docker Volume

1) Соберем образ с *Redis*, который использует *volume*:

```
docker build -t redis_1  -<<EOF

FROM redis
VOLUME /data

EOF
```

2) Запустим контейнер и посмотрим какие *volume'ы* есть:

```
docker run --rm -d --name redis_1 redis_1

docker volume ls
```

3) Нас не устраивает имя *volume*. Остановим контейнер командой `docker stop redis_1`

4) Запустим снова контейнер из этого образа, но передам параметры подключения *volume*:

`docker run --rm --name redis_1 -d --mount type=volume,source=data,destination=/data redis_1`

5) Смотрим теперь список volume'ов, смотрим его физическое расположение на хосте:

```
docker volume ls

ll /var/lib/docker/volumes/data/_data/
```

6) Зайдем внутрь контейнера, создадим там ключ, запишем его в *Redis*, убедимся что rbd файлик создался и выйдем:

```
docker exec -it redis_1 bash

redis-cli

set mykey foobar
get mykey
save
exit

ls
exit
```

7) Посмотрим физическое содержание папки нашего *volume*:

`ls /var/lib/docker/volumes/data/_data/`

8) Остановим наш контейнер и проверим доступность *volume*:

```
docker stop redis_1

docker volume ls
```

9) Запустим снова наш контейнер и убедимся что наш созданный ключ не пропал:

```
docker run --rm --name redis_1 -d --mount type=volume,source=data,destination=/data redis_1

docker exec -it redis_1 bash

redis-cli

get mykey
exit

exit
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:** 

- Запустите контейнер с именем redis_2 из образа redis_1 который будет использовать тот же самый volume
- Для проверки что все получилось зайдите внутрь контейнера redis_2 и в redis_cli и выполните "get mykey"
- Если вы все сделали верно, то отдастся значение foobar.

10) Прибираемся за собой:

```
docker stop $(docker ps -q)

docker volume ls

docker volume rm data
```


------

### Закрепляем тему Docker Compose

1) Устанавливаем *Docker-compose*:

```
yum install docker-compose -y

docker-compose version
```

2) Клонируем себе репозиторий с практикой:

```
cd /srv
git clone git@gitlab.slurm.io:school/slurm.git
```

3) Переходим в каталог с практикой:

`cd /srv/slurm/1.Docker/compose`

4) Запустим наш проект. Это приложение на *Python/Flask*, которое считает количество обращений к нему:

```
docker-compose up -d

curl 127.0.0.1 пару раз
```

5) Смотрим наши *volume'ы* и видим что снова непонятное имя:

`docker volume ls`

6) Останавливаем проект, удаляем *volume*, смотрим соседний файл *compose'а*:

```
docker-compose down
docker volume rm имя_volume'а

cat docker-compose.yml_vol
```

7) Запускаем проект из этого файла:

`docker-compose -f docker-compose.yml_vol up -d `

8) Проверим что наши данные о посещении сохраняются. Сделаем пару обращений к приложению, затем остановим его, снова поднимем и снова сделаем пару обращений:

```
curl 127.0.0.1 пару раз
docker-compose down

docker-compose -f docker-compose.yml_vol up -d
curl 127.0.0.1 пару раз
```

10) Погасим наше приложение: `docker-compose down`

**САМОСТОЯТЕЛЬНАЯ РАБОТА:** 

- Запустить это же приложение, но с *healthcheck'ом* сервиса *redis'а* через команду `redis-cli ping`
- Старт сервиса *web* сделать зависимым от здоровья сервиса *redis*
- Также ограничить через *compose-файл* сервису *redis* *RAM до 500 МБ и CPU до 0,5*
- Проверить что все получилось можно сделав после запуска и получив значения:

```
docker inspect compose_redis_1 | grep "Memory\|NanoCpus"

            "Memory": 524288000,
            "NanoCpus": 500000000,
```

- либо использовав для проверки утилиту cgget.
- Готовый файл для этой самостоятельной работы лежит в этом же репозитории и называется `docker-compose.yml_dz`. Можно использовать как шпаргалку