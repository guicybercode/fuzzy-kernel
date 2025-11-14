# Kubernetes Deployment

Este diretório contém os manifests Kubernetes para deploy do Microkernel IoT Platform.

## Componentes

- **server-deployment.yaml**: Deployment do servidor Elixir/Phoenix
- **server-service.yaml**: Service para expor o servidor
- **edge-deployment.yaml**: Deployment do edge device (Zig)
- **postgres-deployment.yaml**: StatefulSet do PostgreSQL
- **postgres-service.yaml**: Service do PostgreSQL
- **emqtt-deployment.yaml**: Deployment do broker MQTT (EMQ X)
- **emqtt-service.yaml**: Service do EMQ X
- **configmap.yaml**: Configurações compartilhadas
- **secrets.yaml.example**: Exemplo de secrets (copiar e preencher)

## Deploy

1. Criar os secrets:
```bash
cp secrets.yaml.example secrets.yaml
# Editar secrets.yaml com valores reais
kubectl apply -f secrets.yaml
```

2. Aplicar os manifests:
```bash
kubectl apply -f configmap.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f emqtt-deployment.yaml
kubectl apply -f emqtt-service.yaml
kubectl apply -f server-deployment.yaml
kubectl apply -f server-service.yaml
kubectl apply -f edge-deployment.yaml
```

3. Verificar status:
```bash
kubectl get pods
kubectl get services
```

## Acessos

- Servidor: `http://<load-balancer-ip>`
- EMQ X Dashboard: `http://<emqtt-service-ip>:18083`
- Métricas: `http://<load-balancer-ip>/metrics`

