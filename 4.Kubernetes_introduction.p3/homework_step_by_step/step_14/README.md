## 14.** Задача с двумя звездочками.

Сгенерируйте самоподписанный сертификат
создайте из ключа и сертификата секрет типа tls
пропишите в ingress секцию tls и проверьте доступ к вашему сервису по https

### ИСПРАВЛЯЕМ ingress.yml, изменяем placeholder <номер_студента> на номер своего логина.

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
kubectl create secret tls certificate --cert=cert.pem --key=key.pem

vi ingress.yml
kubectl apply -f ingress.yml

curl -k -v https://s<номерстудента>.k8s.slurm.io

curl -k -v https://s<номерстудента>.k8s.slurm.io/app/secret/password
```
