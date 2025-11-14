# TODO - Microkernel IoT Platform

## 🔴 ALTA PRIORIDADE (Funcionalidades Core) ✅ CONCLUÍDO

### 1. Persistir Telemetria no Banco ✅
- [x] Criar migration para tabela `telemetry`
- [x] Schema `Microkernel.Telemetry.Reading`
- [x] Salvar todas as leituras no banco (não só PubSub)
- [x] Índices para queries por device_id e timestamp

### 2. Handler de Comandos MQTT no Edge ✅
- [x] Processar mensagens recebidas no `processMessages`
- [x] Handler para comando "update" (OTA)
- [x] Handler para comando "restart"
- [x] Handler para comando "configure"
- [x] Callback para executar comandos

### 3. API REST ✅
- [x] Controller `DeviceController` (GET /api/devices, GET /api/devices/:id)
- [x] Controller `TelemetryController` (GET /api/telemetry/:device_id)
- [x] Controller `OTAController` (POST /api/devices/:id/update)
- [x] Serializers JSON
- [x] Autenticação básica (API keys)

### 4. Autenticação Básica ✅
- [x] Schema `ApiKey`
- [x] Plug de autenticação
- [x] Proteger rotas sensíveis
- [ ] Login/logout no dashboard (opcional)

## 🟡 MÉDIA PRIORIDADE (Melhorias Importantes) ✅ CONCLUÍDO

### 5. Gráficos Históricos ✅
- [x] LiveView com gráficos (Chart.js ou similar)
- [x] Filtros por data/hora
- [x] Múltiplos sensores no mesmo gráfico
- [x] Exportar dados (CSV/JSON) ✅

### 6. Sistema de Notificações ✅
- [x] Schema `Alert` ou `Notification`
- [x] Regras de alerta (thresholds)
- [x] Notificações para anomalias
- [x] Webhooks para integrações externas

### 7. Busca e Filtros ✅
- [x] Busca de dispositivos por nome/ID
- [x] Filtros por status, firmware version
- [x] Paginação na lista de dispositivos
- [x] Ordenação (nome, status, last_seen)

### 8. Validações e Segurança ✅
- [x] Validação de payloads JSON
- [x] Rate limiting (ex_rated)
- [x] Sanitização de inputs
- [x] CSRF tokens (já implementado)

## 🟢 BAIXA PRIORIDADE (Nice to Have)

### 9. Exportação de Dados ✅
- [x] Endpoint para exportar telemetria (CSV)
- [x] Endpoint para exportar dispositivos (JSON)
- [ ] Agendamento de exports (opcional)

### 10. Multi-tenancy ✅
- [x] Schema `Organization` ou `Tenant`
- [x] Isolamento de dados por tenant (migration criada)
- [ ] Roles e permissões (pendente)

### 11. Métricas Avançadas ✅
- [x] Integração Prometheus
- [x] Endpoint `/metrics` para scraping
- [ ] Dashboard de métricas do sistema (opcional)
- [ ] Alertas baseados em métricas (opcional)

### 12. Documentação API ✅
- [x] OpenAPI/Swagger spec
- [x] Documentação interativa (`/api/docs`)
- [x] Endpoint `/api/swagger.json`

## 🔧 MELHORIAS TÉCNICAS

### 13. Edge (Zig)
- [ ] Implementar TLS real (mbedTLS)
- [ ] Integrar WASM runtime real (wasmtime)
- [ ] Integrar TinyML real (TensorFlow Lite)
- [ ] Drivers de sensores reais (I2C/SPI)
- [ ] Watchdog timer
- [ ] Logging estruturado

### 14. Server (Elixir)
- [ ] Mais testes (cobertura > 80%)
- [ ] Performance testing
- [ ] Load testing
- [ ] Error tracking (Sentry)
- [ ] Logging estruturado (JSON)

### 15. Infraestrutura
- [x] Dockerfile para edge ✅
- [x] Dockerfile para server ✅
- [ ] Kubernetes manifests
- [x] CI/CD pipeline (GitHub Actions) ✅ (criado, precisa commit manual)
- [ ] Terraform para cloud

## 📊 ESTIMATIVA

| Prioridade | Itens | Esforço |
|------------|-------|---------|
| Alta | 4 | 40-60h |
| Média | 4 | 30-50h |
| Baixa | 4 | 40-60h |
| Técnicas | 3 | 60-100h |
| **TOTAL** | **15** | **170-270h** |

## 🎯 PRÓXIMOS PASSOS RECOMENDADOS

1. **Telemetria no banco** - Base para tudo
2. **Handler de comandos** - Funcionalidade crítica
3. **API REST** - Integração externa
4. **Gráficos históricos** - Visualização importante

