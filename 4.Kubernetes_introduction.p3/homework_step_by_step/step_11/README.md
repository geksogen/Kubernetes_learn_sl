## 11. Отредактируйте ingress, чтобы он теперь указывал на новый сервис.

### ИСПРАВЛЯЕМ ingress.yml, изменяем placeholder <номер_студента> на номер своего логина.

проверьте, что по запросу url `/secret/password` отдается содержимое секрета, а по `/` отдается название пода и значение запроса.

```bash
vi ingress.yml

kubectl apply -f ingress.yml

curl s<номер_студента>.k8s.slurm.io
curl s<номер_студента>.k8s.slurm.io/secret/password
```
