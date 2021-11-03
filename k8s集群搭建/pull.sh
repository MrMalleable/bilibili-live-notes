#!/bin/bash
# 拉取镜像
images=(kube-proxy:v1.22.2 kube-scheduler:v1.22.2 kube-controller-manager:v1.22.2 kube-apiserver:v1.22.2 etcd:3.5.0-0 pause:3.5 )
for imageName in ${images[@]} ; do
docker pull registry.aliyuncs.com/google_containers/$imageName
docker tag registry.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
docker rmi registry.aliyuncs.com/google_containers/$imageName
done
