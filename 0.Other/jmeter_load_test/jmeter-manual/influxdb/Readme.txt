torage для influxDB. Папку /local необходимо создать на node-1.root.local.io

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer


apiVersion: v1
kind: PersistentVolume
metadata:
  name: influxdb-data
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 2Gi
  local:
    path: /local
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node-1.root.local.io
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  volumeMode: Filesystem



apiVersion: v1  
kind: PersistentVolumeClaim  
metadata:  
  name: influxdb-data  
spec:  
  accessModes:  
  - ReadWriteOnce  
  resources:  
    requests:  
      storage: 2Gi
  storageClassName: local-storage
