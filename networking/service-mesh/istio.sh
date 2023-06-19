#!/bin/bash

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add kiali https://kiali.org/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

ISTIO_VERSION=1.17.1
KIALI_VERSION=1.64.0
PROMETHEUS_VERSION=19.7.2
NAMESPACE=istio-system

kubectl create ns $NAMESPACE
kubectl label namespace default istio-injection=enabled --overwrite

helm install istio-base istio/base --version $ISTIO_VERSION --namespace $NAMESPACE --wait
helm install istiod istio/istiod --version $ISTIO_VERSION --namespace $NAMESPACE --wait
helm install istio-gateway istio/gateway --version $ISTIO_VERSION --namespace $NAMESPACE
helm install prometheus prometheus-community/prometheus --version $PROMETHEUS_VERSION --namespace $NAMESPACE \
  --set server.global.scrape_interval="10s" \
  --set server.global.evaluation_interval="10s" \
  --set alertmanager.enabled="false" \
  --set kube-state-metrics.enabled="false" \
  --set prometheus-node-exporter.enabled="false" \
  --set prometheus-pushgateway.enabled="false" \
  --wait
helm install kiali kiali/kiali-server --version $KIALI_VERSION --namespace $NAMESPACE \
  --set auth.strategy="anonymous" \
  --set istio.root_namespace="$NAMESPACE" \
  --set external_services.custom_dashboards.prometheus.url="http://prometheus-server/" \
  --set external_services.prometheus.url="http://prometheus-server" \
  --wait

kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | kubectl apply -f -

kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ingress-gateway
spec:
  selector:
    istio: gateway # has to match the pods' label
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
