# Próximos Passos - Microkernel IoT Platform

## ✅ CONCLUÍDO (Alta Prioridade)
- ✅ Persistência de telemetria no banco
- ✅ Handler de comandos MQTT no edge
- ✅ API REST completa
- ✅ Autenticação com API keys

## 🎯 PRÓXIMAS PRIORIDADES

### 1. 🟡 Gráficos Históricos (Média Prioridade)
**Por que fazer agora:** Visualização de dados é essencial para análise

**O que implementar:**
- Adicionar Chart.js ou similar no LiveView
- Página de gráficos históricos por dispositivo
- Filtros por data/hora (última hora, dia, semana, mês)
- Múltiplos sensores no mesmo gráfico
- Zoom e pan nos gráficos

**Arquivos a criar:**
- `server/lib/microkernel_web/live/device_live/charts.ex`
- `server/assets/js/charts.js`
- Rota `/devices/:id/charts`

**Estimativa:** 8-12 horas

---

### 2. 🟡 Sistema de Notificações (Média Prioridade)
**Por que fazer agora:** Alertas são críticos para monitoramento

**O que implementar:**
- Schema `Alert` com regras (thresholds)
- GenServer para monitorar thresholds
- Notificações em tempo real no dashboard
- Webhooks para integrações externas
- Email/SMS (opcional)

**Arquivos a criar:**
- `server/priv/repo/migrations/*_create_alerts.exs`
- `server/lib/microkernel/alerts/`
- `server/lib/microkernel/jobs/alert_check_job.ex`

**Estimativa:** 10-15 horas

---

### 3. 🟡 Busca e Filtros (Média Prioridade)
**Por que fazer agora:** Melhora UX do dashboard

**O que implementar:**
- Busca de dispositivos por nome/ID
- Filtros por status (online/offline)
- Filtros por firmware version
- Paginação (20 por página)
- Ordenação (nome, status, last_seen)

**Arquivos a modificar:**
- `server/lib/microkernel_web/live/device_live/index.ex`
- Adicionar formulário de busca/filtros

**Estimativa:** 4-6 horas

---

### 4. 🟡 Validações e Segurança (Média Prioridade)
**Por que fazer agora:** Segurança é fundamental

**O que implementar:**
- Validação de payloads JSON no MQTT subscriber
- Rate limiting no MQTT (max mensagens/segundo)
- Sanitização de inputs (device_id, etc)
- Validação de versões de firmware
- CSRF já está implementado ✅

**Arquivos a criar/modificar:**
- `server/lib/microkernel_web/plugs/rate_limit.ex`
- `server/lib/microkernel/mqtt/subscriber.ex` (validações)

**Estimativa:** 6-8 horas

---

## 🔧 MELHORIAS TÉCNICAS IMPORTANTES

### 5. Edge - TLS Real
**Status:** Atualmente retorna erro se TLS habilitado
**O que fazer:** Integrar mbedTLS ou similar
**Estimativa:** 12-16 horas

### 6. Edge - WASM Runtime Real
**Status:** Stub que sempre retorna 42
**O que fazer:** Integrar wasmtime ou wasmer
**Estimativa:** 10-14 horas

### 7. Edge - TinyML Real
**Status:** Modelo fake com pesos aleatórios
**O que fazer:** Integrar TensorFlow Lite C API
**Estimativa:** 12-18 horas

### 8. Server - Mais Testes
**Status:** Apenas testes básicos
**O que fazer:** Aumentar cobertura para >80%
**Estimativa:** 8-12 horas

---

## 📋 RECOMENDAÇÃO DE ORDEM

**Fase 1 (Próxima semana):**
1. Gráficos históricos - Visualização essencial
2. Busca e filtros - Melhora UX rapidamente

**Fase 2 (Semana seguinte):**
3. Sistema de notificações - Funcionalidade crítica
4. Validações e segurança - Proteção importante

**Fase 3 (Futuro):**
5. TLS real no edge
6. WASM runtime real
7. TinyML real
8. Mais testes

---

## 🚀 QUICK WINS (Fácil e Impactante)

1. **Adicionar paginação** - 2 horas, melhora muito a UX
2. **Filtro por status** - 1 hora, muito útil
3. **Exportar CSV** - 3 horas, funcionalidade solicitada
4. **Gráfico simples** - 4 horas, visualização básica

---

## 📊 ESTIMATIVA TOTAL RESTANTE

| Categoria | Itens | Horas |
|-----------|-------|-------|
| Média Prioridade | 4 | 28-41h |
| Melhorias Técnicas | 4 | 42-60h |
| Quick Wins | 4 | 10h |
| **TOTAL** | **12** | **80-111h** |

---

**Próximo passo recomendado:** Gráficos históricos (maior impacto visual)

