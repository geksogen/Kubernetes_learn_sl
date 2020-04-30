## 2. Создайте ingress для hostname `my.s<номер_студента>.k8s.slurm.io` и направьте его на сервис, созданный вами в первом шаге.

### ИСПРАВЛЯЕМ ingress.yml, изменяем placeholder <номер_студента> на номер своего логина.

```bash
vi ingress.yml
kubectl apply -f ingress.yml
curl s<номер_студента>.k8s.slurm.io
```
