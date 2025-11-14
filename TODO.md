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

## 🟡 MÉDIA PRIORIDADE (Melhorias Importantes)

### 5. Gráficos Históricos
- [ ] LiveView com gráficos (Chart.js ou similar)
- [ ] Filtros por data/hora
- [ ] Múltiplos sensores no mesmo gráfico
- [ ] Exportar dados (CSV/JSON)

### 6. Sistema de Notificações
- [ ] Schema `Alert` ou `Notification`
- [ ] Regras de alerta (thresholds)
- [ ] Notificações para anomalias
- [ ] Webhooks para integrações externas

### 7. Busca e Filtros
- [ ] Busca de dispositivos por nome/ID
- [ ] Filtros por status, firmware version
- [ ] Paginação na lista de dispositivos
- [ ] Ordenação (nome, status, last_seen)

### 8. Validações e Segurança
- [ ] Validação de payloads JSON
- [ ] Rate limiting no MQTT
- [ ] Sanitização de inputs
- [ ] CSRF tokens (já tem, verificar)

## 🟢 BAIXA PRIORIDADE (Nice to Have)

### 9. Exportação de Dados
- [ ] Endpoint para exportar telemetria (CSV)
- [ ] Endpoint para exportar dispositivos (JSON)
- [ ] Agendamento de exports

### 10. Multi-tenancy
- [ ] Schema `Organization` ou `Tenant`
- [ ] Isolamento de dados por tenant
- [ ] Roles e permissões

### 11. Métricas Avançadas
- [ ] Dashboard de métricas do sistema
- [ ] Integração Prometheus
- [ ] Alertas baseados em métricas

### 12. Documentação API
- [ ] OpenAPI/Swagger spec
- [ ] Documentação interativa
- [ ] Exemplos de uso

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
- [ ] Dockerfile para edge
- [ ] Dockerfile para server
- [ ] Kubernetes manifests
- [ ] CI/CD pipeline (GitHub Actions)
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

