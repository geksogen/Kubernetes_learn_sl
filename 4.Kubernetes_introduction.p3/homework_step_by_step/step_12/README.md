## 12. Добавьте path и второй хост в ingress, таким образом, чтобы:

### ИСПРАВЛЯЕМ ingress.yml, изменяем placeholder <номер_студента> на номер своего логина.

Запросы на url /app отправлялись в поды app
Запросы на url /sec отправлялись в под app-secret

Проверьте с помощью curl.

```bash
vi ingress.yml

kubectl apply -f ingress.yml

curl s<номер_студента>.k8s.slurm.io/app
curl s<номер_студента>.k8s.slurm.io/sec
curl s<номер_студента>.k8s.slurm.io/secret/password

```