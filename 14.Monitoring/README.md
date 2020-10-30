> **Работаем на первом мастере**

### Устанавливаем Prometheus в свой кластер

1) Переходим в папку практики 

```bash
cd slurm/14.Monitoring/
```

2) Правим переменные чарта Prometheus под свой кластер 

```bash
vim ./prometheus/values.yaml
``` 

> **правим <свой номер логина> в ДВУХ местах**

3) Создаем namespace `monitoring` и устанавливаем `Prometheus`: 

```bash
kubectl create ns monitoring

helm install prometheus --namespace monitoring ./prometheus/
```

4) Проверяем что все ОК: 

```bash
kubectl get po -n monitoring
kubectl get ing -n monitoring
```

5) Заходим через режим Инкогнито на `http://prometheus.s<свой номер логина>.edu.slurm.io`

6) Проверим что все работает, введем `container_memory_usage_bytes` и нажмем Enter

7) Проверим LA5 и отфильтруем результат:

```yaml
node_load5

node_load5{kubernetes_node="master-1.s<свой номер логина>.slurm.io"}
```

8) Посмотрим откуда берутся эти метрики. Узнаем IP мастера: 

```bash
kubectl get nodes -o wide | grep master
```

9) "Закурлим" node-exporter, стоящий на мастере: 

```bash
curl ip_адрес_мастера:9100/metrics
```

10) Убедимся, что там есть метрика LA5: 

```bash
curl ip_адрес_мастера:9100/metrics | grep node_load5
```

11) Узнаем как подключен на мониторинг CoreDNS. Для этого откроем сервис `kube-dns` и посмотрим на аннотации:

```bash
kubectl edit svc -n kube-system kube-dns
```

> Видим аннотации в metadata:

```yaml
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
```

12) Вернемся в интерфейс Prometheus и убедимся что CoreDNS там есть, перейдя в раздел Targets

### Установим и настроим Grafana

1) Правим переменные чарта Grafana 

```bash
vim ./grafana/values.yaml
``` 

> **Правим <свой номер логина>**

2) Устанавливаем Grafana: 

```bash
helm install grafana --namespace monitoring ./grafana/
```

3) Для получения пароля админа выполним:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

4) Заходим на `http://grafana.s<свой номер логина>.edu.slurm.io`, логин `admin`, пароль тот, что получили ранее

5) Далее в интерфейсе Grafana переходим в `-> Configutarion -> Data sources -> Add Datasource -> Prometheus`

6) Вводим в поле URL: `http://prometheus-server` затем `Save & Test`

**САМОСТОЯТЕЛЬНАЯ РАБОТА: Подключить в мониторинг Prometheus'a Grafan'у. Для этого нужно**

- Добавить в Service `grafana` необходимые аннотации, по аналогии с CoreDNS
- Убедится что Grafana появилась в разделе Targets Prometheus'a

7) Создадим дашборд в Grafana `Create Dashboard -> Add Query`

8) Впишем в поле *Metrics:* `node_load5`, а в *Legend:* `{{kubernetes_node}}`

9) Добавим уже готовый дашборд. Для этого заходим на сайт https://grafana.com/grafana/dashboards

10) Пишем в поиск `"Kubernetes Deployment Statefulset Daemonset metrics"` и копируем его ID

11) В своей Grafana заходим в `Create -> Import -> вставляем скопированный ID -> Load`

12) Выбираем источником `Prometheus` и нажимаем `Import`

13) Чиним поломанные панели. Исправим подсчет памяти, для этого изменим формулу `Deployment memory usage`:

```bash
sum(container_memory_working_set_bytes{pod!=""}) / sum(kube_node_status_allocatable_memory_bytes) * 100
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:** 

- Подправить часть панели `Deployment memory usage` с именем `Used`
- Убедиться, что `Used` показывает правильное значение

### Настраиваем алертинг через Prometheus

1) Настроим наш AlertManager. Его настройки лежат в Configmap'е. Открываем его на редактирование:

```bash
kubectl edit cm -n monitoring prometheus-alertmanager
```

2) Приводим кусочек конфиг Alertmanager'а к следующему виду:

```yaml
  alertmanager.yml: |
    global: {}
    receivers:
    - name: default-receiver
      email_configs:
      - to: '<свой e-mail адрес>'
        from: 'alertmanager.slurm@yandex.ru'
        smarthost: 'smtp.yandex.ru:465'
        auth_username: 'alertmanager.slurm'
        auth_password: 'Slurm2020'
        require_tls: false
    route:
      group_interval: 5m
      group_wait: 10s
      receiver: default-receiver
      repeat_interval: 3600h
...
```
> Меняем `<свой e-mail адрес>` на какой-нибудь свой e-mail

3) После сохранения Configmap'а Alertmanager'а, переходим к настройке AlertRules. Они настраиваются в Configmap'е Prometheus'а:

```bash
kubectl edit cm -n monitoring prometheus-server
```

4) Приводим кусочек конфига, отвечающего за правила алертинга, к следующему виду:

```yaml
  alerting_rules.yml: |
    groups:
    - name: Test alert
      rules:
      - alert: Pushgateway down
        expr: up{job="prometheus-pushgateway"} == 0
        for: 1m
        labels:
          severity: warning
        annotations:
          title: Prometheus Pushgateway is down
          description: Failed to connect {{ $labels.instance }} for more than 1 minutes.
```

5) Сохраняем конфиг, в котором мы добавили правило алертинга, отслеживающего доступность Pushgateway

6) Симитируем аварию. Заскейлим Deployment Pushgateway'я до 0:

```bash
kubectl scale deployment -n monitoring prometheus-pushgateway --replicas=0
```

7) Переходим в веб-интерфейс Prometheus'а в раздел `Alerts`

8) Ждем пока наш алерт не перейдет в состояние `Firing`

9) Переходим в веб-интерфейс Alertmanager'а: `http://alertmanager.s<ваш номер логина>.edu.slurm.io`

10) Видим наш алерт в списке, его аннотации и время

11) Проверяем свою почту и видим письмо с алертом

> Письмо может идти 1-3 минуты. Если спустя 5 минут письма так и нет, смотрим логи Alertmanager'а

12) Скейлим обратно наш Pushgateway и наблюдаем в веб-интерфейсах Prometheus'а и Alertmanager'а как алерт становится снова неактивным:

```bash
kubectl scale deployment -n monitoring prometheus-pushgateway --replicas=1
```

**ДОМАШНЯЯ РАБОТА:**
- По аналогии с Pushgateway'ем, настроить правило алерта для API-сервера Kubernetes
- Алерт должен "зажигаться", когда API-серверов становится 0
- Настроить алертинг о событии себе на почту
- Срабатывание алерта и доставка письма на почту будет свидетельствовать о правильности выполнения ДЗ
