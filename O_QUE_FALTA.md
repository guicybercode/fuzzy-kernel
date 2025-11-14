# O Que Ainda É Necessário Fazer

## ✅ JÁ IMPLEMENTADO

### Alta Prioridade ✅
- ✅ Persistência de telemetria no banco
- ✅ Handler de comandos MQTT no edge
- ✅ API REST completa
- ✅ Autenticação com API keys

### Média Prioridade ✅
- ✅ Gráficos históricos com Chart.js
- ✅ Sistema de notificações (alerts, webhooks)
- ✅ Busca e filtros no dashboard
- ✅ Validações e segurança (rate limiting, sanitização)

### Infraestrutura Parcial ✅
- ✅ Dockerfiles (edge e server)
- ✅ CI/CD pipeline criado (precisa commit manual)

---

## 🔴 O QUE AINDA FALTA (Por Prioridade)

### 🟡 MÉDIA PRIORIDADE (Pendente)

#### 1. Exportação de Dados
**Status:** Não implementado  
**O que fazer:**
- Endpoint `/api/devices/:id/telemetry/export?format=csv`
- Endpoint `/api/devices/:id/telemetry/export?format=json`
- Agendamento de exports (opcional)

**Arquivos a criar:**
- `server/lib/microkernel_web/controllers/api/export_controller.ex`
- Função de exportação CSV/JSON em `Telemetry`

**Estimativa:** 3-4 horas

---

### 🟢 BAIXA PRIORIDADE

#### 2. Multi-tenancy
**Status:** Não implementado  
**O que fazer:**
- Schema `Organization` ou `Tenant`
- Isolamento de dados por tenant
- Roles e permissões (admin, user, viewer)

**Arquivos a criar:**
- Migration `create_organizations.exs`
- Schema `Microkernel.Organizations.Organization`
- Modificar queries para filtrar por tenant

**Estimativa:** 8-12 horas

#### 3. Métricas Avançadas
**Status:** Não implementado  
**O que fazer:**
- Dashboard de métricas do sistema
- Integração Prometheus
- Alertas baseados em métricas

**Arquivos a criar:**
- `server/lib/microkernel/metrics.ex`
- Endpoint `/metrics` para Prometheus
- Dashboard LiveView para métricas

**Estimativa:** 6-10 horas

#### 4. Documentação API (Swagger/OpenAPI)
**Status:** Não implementado  
**O que fazer:**
- Gerar spec OpenAPI/Swagger
- Documentação interativa
- Exemplos de uso

**Arquivos a criar:**
- `server/lib/microkernel_web/swagger.ex` (usando `phoenix_swagger`)
- Configuração Swagger

**Estimativa:** 4-6 horas

---

### 🔧 MELHORIAS TÉCNICAS (Edge - Zig)

#### 5. TLS Real no Edge
**Status:** Atualmente retorna `error.TlsNotImplemented`  
**O que fazer:**
- Integrar mbedTLS ou BearSSL
- Implementar handshake TLS
- Suporte a certificados

**Arquivos a modificar:**
- `edge/src/mqtt_client.zig` (substituir erro por implementação real)
- `edge/src/tls.zig` (implementar TLS real)

**Dependências:**
- mbedTLS ou BearSSL (biblioteca C)
- Bindings Zig para a biblioteca

**Estimativa:** 12-16 horas

#### 6. WASM Runtime Real
**Status:** Stub que sempre retorna 42  
**O que fazer:**
- Integrar wasmtime ou wasmer
- Carregar módulos WASM reais
- Executar funções WASM

**Arquivos a modificar:**
- `edge/src/wasm_runtime.zig` (substituir stub)

**Dependências:**
- wasmtime C API ou wasmer
- Bindings Zig

**Estimativa:** 10-14 horas

#### 7. TinyML Real
**Status:** Modelo fake com pesos aleatórios  
**O que fazer:**
- Integrar TensorFlow Lite C API
- Carregar modelos TFLite reais
- Inferência real

**Arquivos a modificar:**
- `edge/src/tinyml.zig` (substituir modelo fake)

**Dependências:**
- TensorFlow Lite C API
- Bindings Zig

**Estimativa:** 12-18 horas

#### 8. Drivers de Sensores Reais
**Status:** Abstração genérica apenas  
**O que fazer:**
- Drivers I2C/SPI para sensores reais
- Suporte para DHT22, BMP280, etc.
- GPIO para Raspberry Pi

**Arquivos a criar:**
- `edge/src/drivers/i2c.zig`
- `edge/src/drivers/spi.zig`
- `edge/src/drivers/gpio.zig`
- Drivers específicos (DHT22, BMP280, etc.)

**Estimativa:** 16-24 horas

#### 9. Watchdog Timer
**Status:** Não implementado  
**O que fazer:**
- Timer para reiniciar dispositivo se travar
- Heartbeat monitoring

**Estimativa:** 4-6 horas

#### 10. Logging Estruturado
**Status:** Logs básicos apenas  
**O que fazer:**
- Logs em formato JSON
- Níveis de log configuráveis
- Rotação de logs

**Estimativa:** 4-6 horas

---

### 🔧 MELHORIAS TÉCNICAS (Server - Elixir)

#### 11. Mais Testes
**Status:** Testes básicos existem  
**O que fazer:**
- Aumentar cobertura para >80%
- Testes de integração
- Testes de performance

**Estimativa:** 8-12 horas

#### 12. Performance Testing
**Status:** Não implementado  
**O que fazer:**
- Benchmarks
- Load testing
- Profiling

**Estimativa:** 6-8 horas

#### 13. Error Tracking (Sentry)
**Status:** Não implementado  
**O que fazer:**
- Integrar Sentry
- Capturar erros em produção
- Alertas de erros

**Estimativa:** 2-4 horas

#### 14. Logging Estruturado (JSON)
**Status:** Logs básicos  
**O que fazer:**
- Logs em formato JSON
- Integração com ELK/Loki

**Estimativa:** 3-4 horas

---

### 🔧 INFRAESTRUTURA

#### 15. Kubernetes Manifests
**Status:** Não implementado  
**O que fazer:**
- Deployments para server e edge
- Services
- ConfigMaps e Secrets
- Ingress

**Arquivos a criar:**
- `k8s/server-deployment.yaml`
- `k8s/edge-deployment.yaml`
- `k8s/services.yaml`

**Estimativa:** 6-8 horas

#### 16. Terraform para Cloud
**Status:** Não implementado  
**O que fazer:**
- Infraestrutura como código
- AWS/Azure/GCP
- Auto-scaling

**Estimativa:** 8-12 horas

---

## 📊 RESUMO POR PRIORIDADE

### 🟡 Média Prioridade (1 item)
- Exportação de dados (CSV/JSON) - **3-4h**

### 🟢 Baixa Prioridade (4 itens)
- Multi-tenancy - **8-12h**
- Métricas avançadas - **6-10h**
- Documentação API - **4-6h**
- **Total: 18-28h**

### 🔧 Melhorias Técnicas (10 itens)
- TLS real - **12-16h**
- WASM runtime - **10-14h**
- TinyML real - **12-18h**
- Drivers sensores - **16-24h**
- Watchdog - **4-6h**
- Logging edge - **4-6h**
- Mais testes - **8-12h**
- Performance testing - **6-8h**
- Error tracking - **2-4h**
- Logging server - **3-4h**
- **Total: 77-112h**

### 🔧 Infraestrutura (2 itens)
- Kubernetes - **6-8h**
- Terraform - **8-12h**
- **Total: 14-20h**

---

## 🎯 RECOMENDAÇÕES

### Próximos Passos Imediatos (Quick Wins)
1. **Exportação CSV** - 3h, funcionalidade útil
2. **Error Tracking (Sentry)** - 2h, importante para produção
3. **Logging estruturado** - 3h, facilita debugging

### Próximos Passos Importantes
1. **TLS real no edge** - Crítico para segurança em produção
2. **Mais testes** - Garantir qualidade
3. **Kubernetes manifests** - Facilita deploy

### Para o Futuro
1. **Multi-tenancy** - Se precisar de múltiplos clientes
2. **Drivers de sensores** - Quando tiver hardware real
3. **WASM/TinyML real** - Quando precisar de funcionalidades avançadas

---

## 📈 ESTIMATIVA TOTAL RESTANTE

| Categoria | Itens | Horas |
|----------|-------|-------|
| Média | 1 | 3-4h |
| Baixa | 4 | 18-28h |
| Técnicas | 10 | 77-112h |
| Infra | 2 | 14-20h |
| **TOTAL** | **17** | **112-164h** |

---

**Prioridade recomendada:** Exportação de dados → Error tracking → TLS real → Mais testes

