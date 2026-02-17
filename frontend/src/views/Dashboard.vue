<template>
  <div class="dashboard">
    <header class="dashboard-header">
      <div class="header-content">
        <h1>🏢 Magnus PBX</h1>
        <div class="user-info">
          <span class="tenant-name">{{ userInfo?.tenantName }}</span>
          <span class="extension">Ramal {{ userInfo?.extension }}</span>
          <button @click="handleLogout" class="btn-logout">
            Sair
          </button>
        </div>
      </div>
    </header>

    <main class="dashboard-main">
      <div class="container">
        <!-- Status de conexão -->
        <div class="connection-status" :class="{ connected: isConnected }">
          <span class="status-dot"></span>
          {{ isConnected ? 'Conectado' : 'Desconectado' }}
        </div>

        <!-- Seção de controle do portão -->
        <section class="gate-control-section">
          <div class="card">
            <h2 class="card-title">🚪 Controle de Portão</h2>
            <p class="card-description">
              Use o botão abaixo para abrir o portão da entrada principal.
            </p>
            <div class="button-container">
              <OpenGateButton />
            </div>
          </div>
        </section>

        <!-- Seção de logs -->
        <section class="logs-section">
          <GateLogList />
        </section>

        <!-- Event listener para SignalR (opcional - para debugging) -->
        <div v-if="lastGateEvent" class="realtime-event">
          <strong>Evento em tempo real:</strong>
          {{ lastGateEvent.action }} por {{ lastGateEvent.extension }}
          às {{ formatTime(lastGateEvent.timestamp) }}
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import { useSignalR } from '@/composables/useSignalR';
import OpenGateButton from '@/components/OpenGateButton.vue';
import GateLogList from '@/components/GateLogList.vue';

const router = useRouter();
const authStore = useAuthStore();
const { isConnected, lastGateEvent } = useSignalR();

const userInfo = computed(() => authStore.userInfo);

function handleLogout() {
  authStore.logout();
  router.push('/login');
}

function formatTime(timestamp: string): string {
  return new Date(timestamp).toLocaleTimeString('pt-BR');
}
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.dashboard-header {
  background: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 10;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dashboard-header h1 {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.tenant-name {
  font-weight: 600;
  color: #374151;
}

.extension {
  font-family: monospace;
  background: #f3f4f6;
  padding: 0.25rem 0.75rem;
  border-radius: 0.375rem;
  color: #6b7280;
  font-size: 0.875rem;
}

.btn-logout {
  padding: 0.5rem 1rem;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

.btn-logout:hover {
  background: #dc2626;
}

.dashboard-main {
  padding: 2rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.connection-status {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  background: white;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  margin-bottom: 1.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #6b7280;
}

.connection-status.connected {
  color: #065f46;
  background: #d1fae5;
}

.status-dot {
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  background: #ef4444;
  animation: pulse 2s ease-in-out infinite;
}

.connection-status.connected .status-dot {
  background: #10b981;
}

.gate-control-section {
  margin-bottom: 2rem;
}

.card {
  background: white;
  border-radius: 0.75rem;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.card-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 0.5rem 0;
}

.card-description {
  color: #6b7280;
  margin: 0 0 1.5rem 0;
}

.button-container {
  display: flex;
  justify-content: center;
  padding: 1rem 0;
}

.logs-section {
  margin-top: 2rem;
}

.realtime-event {
  margin-top: 1rem;
  padding: 1rem;
  background: #fef3c7;
  border-left: 4px solid #f59e0b;
  border-radius: 0.375rem;
  color: #92400e;
  font-size: 0.875rem;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

/* Responsivo */
@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 1rem;
  }

  .user-info {
    flex-direction: column;
    width: 100%;
  }

  .dashboard-main {
    padding: 1rem;
  }

  .card {
    padding: 1.5rem;
  }
}
</style>
