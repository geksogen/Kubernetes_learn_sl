Создание image
 buildah bud -f ./Dockerfile -t hello world
 
Push local
 buildah push localhost/my-app-buildah docker-daemon:my-app-buildah:latest
 
Push registry
 buildah push --creds geksogen: 5f3deb307c6a docker://geksogen/learn_images:test

Запуск контейнера из registry 
 docker run -p 5000:5000 geksogen/learn_images:test

Под для тестирования
kubectl run -t -i --rm --image amouat/network-utils test bash

Проверка <IP Kubernetes services>
curl 10.100.84.84:500 /


https://www.magalix.com/blog/demystifying-docker-kubernetes-for-your-organization 