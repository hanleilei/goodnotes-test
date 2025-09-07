#!/bin/bash
# scripts/setup-cluster.sh

set -e

echo "🚀 Creating KinD cluster with port..."

# 删除现有集群（如果存在）
kind delete cluster --name load-test-cluster || true

# 创建新集群
kind create cluster --config=k8s/kind-config.yaml

echo "📋 Cluster information:"
kubectl cluster-info --context kind-load-test-cluster

echo "📊 Node status:"
kubectl get nodes -o wide

echo "🐳 Docker port mappings:"
docker port load-test-cluster-control-plane

echo "✅ Cluster setup completed!"