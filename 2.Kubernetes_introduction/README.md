### Перед стартом практики

1) Заходим **по SSH** на sbox таким образом `ssh sXXXXXX@sbox.slurm.io`

Где `sXXXXXX` - это номер вашего имени пользователя. Учетные данные доступны в [личном кабинете](https://edu.slurm.io/profile)

2) Подключившись к sbox, проверяем что есть подключение к кластеру, выполнив `kubectl get pod`

3) Сообщение `No resources found in sXXXXXX namespace.` говорит что все работает

4) Клонируем себе репозиторий: `cd ~ && git clone git@gitlab.slurm.io:school/slurm.git`

### Закрепляем знания по Pod и Replicaset

1) Переходим в каталог с практикой, смотрим файл `pod.yaml` и запускаем его

```
cd slurm/2.Kubernetes_introduction/
cat pod.yaml
kubectl create -f pod.yaml
```
 
2) Проверяем что наш pod действительно стартанул:

```
kubectl get po
```

3) Посмотрим описание этого pod'а, статус и его events:

```
kubectl describe pod my-pod
```

4) Посмотрим на наш replicaset, запустим его:

```
cat replicaset.yaml
kubectl create -f replicaset.yaml
```

5) Обратите внимание, что теперь и pod и replicaset работают:

```
kubectl get po
kubectl get rs
```

6) Увеличим количество реплик нашего replicaset до 3, убедимся что все сработало:

```
kubectl scale replicaset my-replicaset --replicas=3

kubectl get po
kubectl get rs
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:**

- Уменьшить количество реплик запущенного replicaset до 2 НЕ используя `kubectl scale`

7) Прибираемся за собой

```
kubectl delete all --all
```

---

### Закрепляем знания по Deployment

1) Смотрим на `deployment.yaml`, НО НЕ ЗАПУСКАЕМ ПОКА ЧТО

```
cat deployment.yaml
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:**

- Запустить Deployment с image=nginx:1.13
- У этого деплоймента должно быть 6 реплик
- Этот деплоймент должен при обновлении увеличивать количество новых реплик на 2
- Этот деплоймент должен при обновлении уменьшать количество старых реплик на 2

2) Обновляем версию нашего деплоймента до nginx:1.14 и сразу смотрим как проходит процесс обновления:

```
kubectl set image deployment my-deployment '*=nginx:1.14'
kubectl get po -w
```

3) Удалим наш deployment:

```
kubectl delete deployment my-deployment
```

---

### Закрепляем знания по resources

1) Посмотрим на `deployment-with-stuff.yaml` и запустим его:

```
cat deployment-with-stuff.yaml
kubectl create -f deployment-with-stuff.yaml
```

2) Посмотрим `describe` этого deployment,увидим его Requests и Limits:

```
kubectl describe deployments.apps my-deployment
```

3) Обратим внимание на QoS класс запущенных подов deployment'а:

```
kubectl describe po my-deployment-XXXXXXXXXX-YYYYY | grep QoS
```

---

### Закрепляем знания по probes

1) Снова посмотрим файл ранее запущенного нами deployment'а `deployment-with-stuff.yaml`:

```
cat deployment-with-stuff.yaml
```

2) Обновим наш deployment. Для этого изменим в файле `deployment-with-stuff.yaml` поле `- image: nginx:1.12` на `- image: nginx:1.13`. Применяем и смотрим как происходит обновление: 

```
kubectl apply -f deployment-with-stuff.yaml
kubectl get po -w
```

3) Повторим все тоже самое, но теперь изменим в файле `deployment-with-stuff.yaml` поле `- image: nginx:1.13` на `- image: nginx:1.14`. Применяем и смотрим какие replicaset'ы есть:

```
kubectl apply -f deployment-with-stuff.yaml
kubectl get po -w
kubectl get rs
```

4) Представим что в коде последних двух версий обнаружили баг, нам нужно откатиться обратно на старый образ `nginx:1.12`. Можно поменять в файле, а можно воспользоваться командой:

```
kubectl rollout undo deployment my-deployment --to-revision=1
```

5) Проверим текущий image нашего deployment:

```
kubectl describe deployments.apps my-deployment | grep Image
```

6) Удаляем deployment

```
kubectl delete deployment my-deployment
```

7) Смотрим на файл `deployment-startup-probe.yaml`, попробуем его применить:

```
cat deployment-startup-probe.yaml

kubectl create -f deployment-startup-probe.yam
```

8) Посмотрим его describe и видим что там только две пробы, так как на 1.16 версии kubernetes `StartupProbe` в Alpha версии:

```
kubectl describe deployments.apps my-deployment
```

9) Прибираем за собой: 

```
kubectl delete all --all
```

**ДОМАШНЯЯ РАБОТА:**

- Запустить deployment из файла `bad_deployment.yaml`
- Понять почему pod'ы не становятся в статус Running и исправить это
- Пофиксить все остальные проблемы
- Как итог, все поды должны быть в статусе Running и в READY 1/1

*Ответ-шпаргалка в `bad_deployment.yaml_otvet`*