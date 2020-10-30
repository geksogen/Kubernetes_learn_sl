## ВНИМАНИЕ!

**!!!Всю практику выполняем на своем `master-1.sXXXXXX` ПОД РУТОМ (sudo -i) , предварительно зайдя на него по SSH!!!**

0) На `master-1` клонируем git-репо:

```
cd /srv
git clone git@gitlab.slurm.io:school/slurm.git

cd slurm/9.Helm
```

### Установим приложение через Helm:

1) Подключаем repo и смотрим values kube-ops-view

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

helm search hub kube-ops
helm show values stable/kube-ops-view > values.yaml

```

2) Правим `values.yaml`:

```
ingress:
  enabled: true
...
hostname: kube-ops.sXXXXXX.edu.slurm.io
...
rbac:
  create: true
...
```
где `sXXXXXX` - ваш номер студента

3) Устанавливаем kube-ops-view:

```
helm install ops-view stable/kube-ops-view --namespace kube-system -f values.yaml
```

4) Переходим в браузер в Инкогнито режим и заходим на `http://kube-ops.sXXXXXX.edu.slurm.io/`

5) Удаляем чарт:

```
helm delete ops-view --namespace kube-system
```

### Посмотрим, что внутри чарта:

```
helm pull stable/kube-ops-view

tar -zxvf kube-ops-view-1.2.0.tgz

cd kube-ops-view/
```

### Создадим свой чарт

1) Возьмем за основу нашего чарта готовый Depolyment. Создадим папку будущего чарта и создадим внутри необходимые файлы и папки:

```
cd /srv
mkdir myapp

cd myapp

touch Chart.yaml values.yaml
mkdir templates

cp /srv/slurm/9.Helm/simple-deployment.yaml /srv/myapp/templates/
```

2) Добавим в файл `Chart.yaml` минимально необходимые поля:

```
name: myapp
version: 1
```

3) Проверим что рендеринг чарта работает, в выводе команды должны увидеть наш Deployment

```
helm template .
```

### Темплейтируем свой чарт

0) Если отстали, сверяемся с файлом `summary_file.yaml`

1) Смотрим на файл `templates/simple-deployment.yaml` и темплейтируем в нем количество реплик и image

```
replicas: 1

меняем на

replicas: {{ .Values.replicas }}

...

image: nginx:1.14.2

меняем на

image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}" 
```

2) Добавляем значения этих переменных в файл `values.yaml`:

```
replicas: 3

image:
  repository: nginx
  tag: 1.12
```

3) Проверяем что все корректно и что наши values подцепились:

```
helm template .
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:**
- Затемплейтировать по аналогии в Deployment значение поля `containerPort: 80`

### Стандартизируем наш чарт

1) Заменяем все лейблы в Deployment, а также имя деплоймента и контейнера

```
  labels:
    app: nginx

меняем на

  labels:
    app: {{ .Chart.Name }}-{{ .Release.Name }}

---

name: nginx-deployment

меняем на

name: {{ .Chart.Name }}-{{ .Release.Name }}

---

      containers:
      - name: nginx

меняем на

      containers:
      - name: {{ .Chart.Name }}

```

2) Для проверки используем ту же команду, но с доп ключом:

```
helm template . --name-template foobar
```

3) Указываем количество реплик по-умолчанию:

```
{{ .Values.replicas | default 2 }}
``` 

4) Проверяем изменения, а также пробуем переназначить тэг образа через ключ `--set`:

```
helm template . --name-template foobar --set image.tag=1.13
```

### Добавляем в наш Deployment `requests/limits`

1) Добавляем в `values.yaml` реквесты и лимиты, прям в их обычном формате:

```
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 80m
    memory: 64Mi
```

2) В нашем темплейтированном манифесте говорим, чтобы за ресурсами он сходил в `values.yaml` и взял оттуда секцию целиком:

```
        ports:
        - containerPort: {{ .Values.service.internalPort }}
        resources:    <--- вставляем в это место
{{ toYaml .Values.resources }}

```

3) Проверяем изменения

```
helm template . --name-template foobar
```

4) Видим что не хватает отступов. Добавляем `indent` в наш Deployment:

```
было

{{ toYaml .Values.resources }}

стало

{{ toYaml .Values.resources | indent 10 }}
```

5) Проверяем исправилось ли 

```
helm template . --name-template foobar
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:**
- Добавить таким же образом `annotations`
- Поиграйтесь с indent'ом. Сделайте так, чтобы при рендеринге показывались верные отступы
- В `values.yaml` укажите значение аннотации `abc: xyz`

6) Добавляем условие в аннотации:

```
было

  annotations:
{{ toYaml .Values.annotations | indent 4 }}

стало

{{ if .Values.annotations }}
  annotations:
{{ toYaml .Values.annotations | indent 4 }}
{{ end }}

```

7) Смущают пустые строчки. Уберем их

```
было

{{ if .Values.annotations }}
  annotations:
{{ toYaml .Values.annotations | indent 4 }}
{{ end }}

стало

{{- if .Values.annotations }}
  annotations:
{{ toYaml .Values.annotations | indent 4 }}
{{- end }}

```

8) Проверяем что теперь все ОК

```
helm template . --name-template foobar
```

### Добавляем указание переменных окружения

1) Вносим в наш темплейтированный манифест следующее:

```
        - containerPort: {{ .Values.port }}
{{ if .Values.env }}    <--- Сюда вставляем
        env:
        {{ range $key, $val := .Values.env }}
        - name: {{ $key | quote }}
          value: {{ $val | quote }}
        {{ end }}
{{ end }}

```

2) Проверяем что ничего не сломали

```
helm template . --name-template foobar
```

3) Добавляем в `values.yaml` переменные окружения:

```
env:
  one: two
  ENV: DEVELOPMENT
```

4) Проверяем что переменные подтянулись

```
helm template . --name-template foobar
```

**ДОМАШНЯЯ РАБОТА:**
- Убрать лишние строчки при рендеринге манифеста
- Верный ответ лежит в файле `summary_file.yaml`

### Дополнительная информация:

1) Через файл `_helpers.tpl` можно задавать дополнительные переменные (можно подсмотреть у kube-ops-view)

2) Упростить задачу создания своего шаблона чарта можно использовав команду `helm create <<имя_чарта>>`
 
### Helm Cheatsheet

Поиск чартов

```
helm search hub
```

Получение дефолтных values

```
helm show values repo/chart > values.yaml
```

Установка чарта в кластер

```
helm install release-name repo/chart [--atomic] [--namespace namespace]
```

Локально отрендерить чарт

```
helm template /path/to/chart
```

---
