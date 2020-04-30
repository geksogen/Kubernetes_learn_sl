## 1. Создайте деплоймент `app` на базе образа nginx:1.17 и сервис на порт 80

```
kubectl run app --image nginx:1.17 --expose --port 80
```

## 2. Создайте ingress для hostname `my.s<номер_студента>.k8s.slurm.io` и направьте его на сервис, созданный вами в первом шаге.

```
vi ingress.yaml

kubectl apply -f ingress.yaml

curl s<номер студента>.k8s.slurm.io
```

## 3. Создайте конфиг мап из файла `default.conf` с конфигурацией nginx.

```
kubectl create configmap app --from-file=default.conf
```

## 4. Добавьте в деплоймент монтирование созданного configmap как файл в каталог `/etc/nginx/conf.d`

```
kubectl edit depoly app

## Добавляем volumeMounts: в контейнер с ngninx и volumes: в спецификацию пода
## Добавляемы строчки помечены символом +
## diff:
    spec:
      containers:
      - image: nginx:1.17
        imagePullPolicy: IfNotPresent
        name: app
        ports:
        - containerPort: 80
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
+       volumeMounts:
+       - name: config
+         mountPath: /etc/nginx/conf.d
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
+     volumes:
+     - name: config
+       configMap:
+         name: app


curl s<номер студента>.k8s.slurm.io
```

## 5. Создайте секрет с ключом password

```
kubectl create secret generic app-secret --from-literal=password=mysupersecret
```

## 6. Создайте configmap из файла default-secret.conf

```
kubectl create configmap app-secret --from-file=default-secret.conf
```

## 7. Создайте копию деплоймента `app`

```
kubectl get deploy app -o yaml --export >app-secret.yaml
```

## 8. Отредактируйте манифест в файле appsecret.yaml

mountpath: /opt/secret, потому что с указанной в задании точкой монтирования nginx по требуемум адресу возвращает 404. и точку монтирования надо изменить.

```
vi app-secret.yaml
## diff:

   creationTimestamp: null
   generation: 1
   labels:
-    run: app
-  name: app
+    run: app-secret
+  name: app-secret
   selfLink: /apis/apps/v1/namespaces/default/deployments/app
 spec:
   progressDeadlineSeconds: 600
@@ -15,7 +15,7 @@ spec:
   revisionHistoryLimit: 10
   selector:
     matchLabels:
-      run: app
+      run: app-secret
   strategy:
     rollingUpdate:
       maxSurge: 25%
@@ -25,12 +25,12 @@ spec:
     metadata:
       creationTimestamp: null
       labels:
-        run: app
+        run: app-secret
     spec:
       containers:
       - image: nginx:1.17
         imagePullPolicy: IfNotPresent
-        name: app
+        name: app-secret
         ports:
         - containerPort: 80
           protocol: TCP
@@ -40,6 +40,8 @@ spec:
         volumeMounts:
         - mountPath: /etc/nginx/conf.d
           name: config
+        - mountPath: /opt/secret
+          name: opt
       dnsPolicy: ClusterFirst
       restartPolicy: Always
       schedulerName: default-scheduler
@@ -48,6 +50,9 @@ spec:
       volumes:
       - configMap:
           defaultMode: 420
-          name: app
+          name: app-secret
         name: config
+      - secret:
+          secretName: app-secret
+        name: opt

```

## 9. Примените манифест в кластер и убедитесь что второе приложение запустилось.

```
kubectl apply -f app-secret.yaml

kubectl get pod
# Если под не запускается, можно посмотреть что происходит командами

kubectl describe
kubectl logs
```

## 10. Повторите действия с копированием сервиса, не забудьте исправить метки в поле `selector` сервиса

```
kubectl get svc app -o yaml --export >svc-secret.yaml

vi svc-secret.yaml
## diff:
<   name: app
---
>   name: app-secret
13c13
<     run: app
---
>     run: app-secret

kubectl apply -f svc-secret.yaml

kubectl get pod -o wide
kubectl get ep
```

## 11. Отредактируйте ingress, чтобы он теперь указывал на новый сервис.

```
kubectl edit ing app
## diff:

-          serviceName: app
+          serviceName: app-secret

curl s<номер студента>.k8s.slurm.io
curl s<номер студента>.k8s.slurm.io/secret/password
```

## 12. Добавьте path и второй хост в ingress, таким образом, чтобы:

```
kubectl edit ing app
## diff:
        paths:
        - backend:
            serviceName: app-secret
            servicePort: 80
          path: /sec
        - backend:
            serviceName: app
            servicePort: 80
          path: /app
```

## 13.* Задача со звездочкой.

Пожалуйста решайте самостоятельно.

## 14.*

```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
kubectl create secret tls certificate --cert=cert.pem --key=key.pem
```

add to ingress:
```
  tls:
    - hosts:
      - s000099.k8s.slurm.io
        secretName: certificate
```

```
curl -k -v https://s000099.k8s.slurm.io
```
