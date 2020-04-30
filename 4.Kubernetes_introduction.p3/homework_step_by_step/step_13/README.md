## 13.* Задача со звездочкой.

Измените конфигурацию ингрессов таким образом, чтобы запросы на `/app` отправлялись в поды `app`, на `/sec` в поды `appsecret`,
но в то же время по запросу `/app/secret/password` отдавалось содержимое секрета.

### ИСПРАВЛЯЕМ ingress.yml и ingress_2.yml, изменяем placeholder <номер_студента> на номер своего логина.

Проверьте с помощью curl.

```bash
vi ingress.yml

kubectl apply -f ingress.yml
kubectl apply -f ingress_2.yml

curl s<номер_студента>.k8s.slurm.io/app
curl s<номер_студента>.k8s.slurm.io/sec
curl s<номер_студента>.k8s.slurm.io/app/secret/password
```
