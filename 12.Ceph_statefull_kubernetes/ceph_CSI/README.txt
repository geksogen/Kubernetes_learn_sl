ph CSI driver
Добавляем репо и скачиваем себе cephfs.yml для настройки
helm repo add ceph-csi https://ceph.github.io/csi-charts
helm inspect values ceph-csi/ceph-csi-cephfs >cephfs.yml

Смотрим ceph sid и IP мониторов
8a72cf06-87f6-432c-b057-35073bae8d5f ceph sid
192.168.0.4:6789		     ceph mon dump

Пример настройки cephfs.yaml
csiConfig:
  - clusterID: "bcd0d202-fba8-4352-b25d-75c89258d5ab"
    monitors:
      - "172.18.8.5:6789"
      - "172.18.8.6:6789"
      - "172.18.8.7:6789"

nodeplugin:
  httpMetrics:
    enabled: true
    containerPort: 8091
  podSecurityPolicy:
    enabled: true

provisioner:
  replicaCount: 1
  podSecurityPolicy:
    enabled: true

	
Устанавливаем чарт
helm upgrade -i ceph-csi-cephfs ceph-csi/ceph-csi-cephfs -f cephfs.yml -n ceph-csi-cephfs --create-namespace

Смотрим ID admin
ceph auth get-key client.admin
AQD9zu9ePGYqLhAAUV7aHgdETMxJv6ncrLsFow==

Создаем секрет для Kube в созданом ранее namespace ceph-csi-cephfs. Namespace создается когда ставим helm чарт
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-cephfs-secret
  namespace: ceph-csi-cephfs
stringData:
  # Required for dynamically provisioned volumes
  adminID: admin
  adminKey: AQD9zu9ePGYqLhAAUV7aHgdETMxJv6ncrLsFow== 
  
Создаем storageclass
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cephfs-sc
provisioner: cephfs.csi.ceph.com
parameters:
  clusterID: 8a72cf06-87f6-432c-b057-35073bae8d5f

  # CephFS filesystem name into which the volume shall be created
  fsName: cephfs

  # (optional) Ceph pool into which volume data shall be stored
  # pool: cephfs_data

  # (optional) Comma separated string of Ceph-fuse mount options.
  # For eg:
  # fuseMountOptions: debug

  # (optional) Comma separated string of Cephfs kernel mount options.
  # Check man mount.ceph for mount options. For eg:
  # kernelMountOptions: readdir_max_bytes=1048576,norbytes

  # The secrets have to contain user and/or Ceph admin credentials.
  csi.storage.k8s.io/provisioner-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph-csi-cephfs
  csi.storage.k8s.io/controller-expand-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ceph-csi-cephfs
  csi.storage.k8s.io/node-stage-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/node-stage-secret-namespace: ceph-csi-cephfs

  # (optional) The driver can use either ceph-fuse (fuse) or
  # ceph kernelclient (kernel).
  # If omitted, default volume mounter will be used - this is
  # determined by probing for ceph-fuse and mount.ceph
  # mounter: kernel
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
  - debug
  
 Создаем PVC https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/ 
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-cephfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: csi-cephfs-sc
  
Если мы создали секрет и сторадж класс- то их можно использовать много раз для PVC-PV-Deployment

Закинуть файл curl -i fileshare.s<номер своего логина>.edu.slurm.io/files/ -T configmap.yaml
 

