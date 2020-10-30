> **Работаем на первом мастере**

### Устанавливаем Grafana и подключаем Loki

1) Правим переменные чарта Grafana 

```bash
vim ./grafana/values.yaml
``` 

> **Правим <свой номер логина>**

2) Устанавливаем Grafana в созданный namespace: 

```bash
kubectl create ns monitoring

helm install grafana --namespace monitoring ./grafana/
```

3) Для получения пароля админа выполним:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

4) Заходим на `http://grafana.s<свой номер логина>.edu.slurm.io`, логин `admin`, пароль тот, что получили ранее

5) Ставим Loki: 

```bash
helm install loki --namespace monitoring ./loki-stack/
```

6) Подключаем Loki в Grafana: `Add Datasource -> Loki -> http://loki:3100`

7) Чтобы посмотреть логи через Loki в Grafana заходим в `Explore -> Loki`

8) Удаляем Loki чтобы освободить ресурсы: 

```bash
helm delete loki -n monitoring
```

### Устанавливаем EFK-стек

1) Устанавливаем Elasticsearch: 

```bash
helm install elastic --namespace monitoring ./elasticsearch/
```

2) Правим переменные чарта Kibana 

```bash
vim ./kibana/values.yaml
```

> **Правим <свой номер логина>**

3) Ставим Kibana: 

```bash
helm install kibana --namespace monitoring ./kibana/
```

4) Ставим Fluent-bit: 

```bash
helm install fluent-bit --namespace monitoring ./fluent-bit/
```

5) Заходим в Kibana по адресу `http://kibana.s<ваш номер логина>.edu.slurm.io`

6) Далее идем в `Management -> Create index, пишем "kubernetes_cluster*" -> выбираем @timestamp -> Create pattern index`

7) Переходим в `Discover, выбираем "kubernetes_cluster*"`

8) Видим подгруженные логи, пробуем отфильтровать запросом: `kubernetes.pod_name:nginx-ingress-controller AND stream:stderr`

### Подключаем в Kibana плагин ElastAlert

1) Правим values чарта Kibana, приведя раздел `plugin` к виду:

```bash
vim ./kibana/values.yaml
```

```yaml
plugins:
  # set to true to enable plugins installation
  enabled: true  <--- меняем на true
  # set to true to remove all kibana plugins before installation
  reset: false
  # Use <plugin_name,version,url> to add/upgrade plugin
  values:
    - elastalert-kibana-plugin,1.0.1,https://github.com/bitsensor/elastalert-kibana-plugin/releases/download/1.0.1/elastalert-kibana-plugin-1.0.1-6.4.2.zip <--- раскомментируем
```

2) Обновляем наш чарт Kibana:

```bash
helm upgrade --install kibana ./kibana/ --namespace monitoring
```

3) Смотрим pod'ы, видим проблему:

```bash
kubectl get po -n monitoring  -w
```

**САМОСТОЯТЕЛЬНАЯ РАБОТА:**
- Понять, что произошло с Kibana и решить проблему
- Воспользуйтесь для дебага уже известными вам инструментами из лекции Disaster Recovery

4) Заходим в Kibana через браузер, и видим там появившийся раздел `ElastAlert`. Но при переходе на него получаем ошибку

5) Разберемся что не так. Установим `kubectl-debug`

```bash
export PLUGIN_VERSION=0.1.1

curl -Lo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v${PLUGIN_VERSION}/kubectl-debug_${PLUGIN_VERSION}_linux_amd64.tar.gz

tar -zxvf kubectl-debug.tar.gz kubectl-debug
mv kubectl-debug /usr/local/bin/

kubectl apply -f https://raw.githubusercontent.com/aylei/kubectl-debug/master/scripts/agent_daemonset.yml
```

6) Подключимся через kubectl-debug к pod'у Kibana и проверим порты:

```bash
kubectl-debug -n monitoring kibana-<имя-пода>

netstat -nlp
```

7) Видим что порта и процесса нет. Ставим ElastAlert сами

```bash
vim elastalert/elastalert_kube_not_normal.yaml
```

> Меняем <свой номер логина>

```bash
ssh node-2.s<свой номер логина>.slurm.io
cd /srv
git clone git@gitlab.slurm.io:school/slurm.git

exit

kubectl create -f elastalert/elastalert_kube_not_normal.yaml -n monitoring
```

8) Теперь научим плагин Kibana ElastAlert ходить в наш ElastAlert pod. Для этого правим values нашего чарта Kibana и передеплоим его:

```bash
vim kibana/values.yaml
```

```yaml
files:
  kibana.yml:
    ## Default Kibana configuration from kibana-docker.
    server.name: kibana
    server.host: "0"
    ## For kibana < 6.6, use elasticsearch.url instead
    elasticsearch.hosts: http://elastic-elasticsearch-client:9200

    elastalert-kibana-plugin.serverHost: elasticalert  <-- вставляем эту строчку

```

```bash
helm upgrade --install kibana ./kibana/ --namespace monitoring
```

9) Перезайдем в `Kibana -> ElastAlert` и увидим что все заработало

### Пишем правило алертинга для ElastAlert

1) В разделе ElastAlert у Kibana нажимаем `Create Rule`

2) Помещаем в правило следующее:

```yaml
filter:
- query_string:
    query: "kubernetes.labels.app: nginx-ingress AND log: 404"

type: frequency

num_events: 1

index: kubernetes_cluster*

timeframe:
  hours: 1
  
alert:
- "email"

email:
 - "alertmanager.slurm@yandex.ru" <-- можно поменять на свой адрес

smtp_host: "smtp.yandex.ru"
smtp_port: "465"
from_addr: "alertmanager.slurm@yandex.ru"
smtp_auth_file: "/opt/elastalert/smtp.yaml"
smtp_ssl: true

es_host: elastic-elasticsearch-client
```

3) Заходим на какой-нибудь несуществующий адрес на Ingress-controller'е, например `http://kibana.s<свой номер логина>.edu.slurm.io/123`

4) После этого ждем письма с алертом

**ДОМАШНЯЯ РАБОТА:**
- Манифест `elastalert_kube_not_normal.yaml` привести в порядок. Убрать Hostpath, заменить подключение конфигов с локальной папки на Configmap
- Pod превратить в Deployment, и убрать nodeSelector
- Высшим пилотажем будет написать Helm чарт установки ElastAlert'а
