<template>
  <div class="gate-log-list">
    <div class="header">
      <h2>📋 Histórico de Acessos</h2>
      <button @click="refreshLogs" :disabled="isLoading" class="btn-refresh">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          :class="{ 'animate-spin': isLoading }"
          class="icon"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99"
          />
        </svg>
        Atualizar
      </button>
    </div>

    <!-- Loading state -->
    <div v-if="isLoading && logs.length === 0" class="loading">
      Carregando logs...
    </div>

    <!-- Empty state -->
    <div v-else-if="logs.length === 0" class="empty">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="empty-icon"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 00-1.883 2.542l.857 6a2.25 2.25 0 002.227 1.932H19.05a2.25 2.25 0 002.227-1.932l.857-6a2.25 2.25 0 00-1.883-2.542m-16.5 0V6A2.25 2.25 0 016 3.75h3.879a1.5 1.5 0 011.06.44l2.122 2.12a1.5 1.5 0 001.06.44H18A2.25 2.25 0 0120.25 9v.776"
        />
      </svg>
      <p>Nenhum registro encontrado</p>
    </div>

    <!-- Logs table -->
    <div v-else class="table-container">
      <table class="logs-table">
        <thead>
          <tr>
            <th>Data/Hora</th>
            <th>Ramal</th>
            <th>Ação</th>
            <th>IP</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in logs" :key="log.id" :class="getRowClass(log.action)">
            <td>{{ formatDate(log.openedAt) }}</td>
            <td class="extension">{{ log.extension }}</td>
            <td>
              <span :class="getActionClass(log.action)" class="action-badge">
                {{ getActionIcon(log.action) }} {{ getActionText(log.action) }}
              </span>
            </td>
            <td class="ip">{{ log.ipAddress || '-' }}</td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="totalCount > pageSize" class="pagination">
        <button
          @click="goToPage(currentPage - 1)"
          :disabled="currentPage === 1"
          class="btn-page"
        >
          ← Anterior
        </button>
        <span class="page-info">
          Página {{ currentPage }} de {{ totalPages }} ({{ totalCount }} registros)
        </span>
        <button
          @click="goToPage(currentPage + 1)"
          :disabled="currentPage === totalPages"
          class="btn-page"
        >
          Próxima →
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { gateService, type GateLog } from '@/services/gateService';
import { useSignalR } from '@/composables/useSignalR';

const logs = ref<GateLog[]>([]);
const isLoading = ref(false);
const currentPage = ref(1);
const pageSize = ref(10);
const totalCount = ref(0);

const totalPages = computed(() => Math.ceil(totalCount.value / pageSize.value));

// Conecta SignalR para updates em tempo real
const { lastGateEvent } = useSignalR();

// Watch para atualizar logs quando evento real-time chegar
// watch(lastGateEvent, (newEvent) => {
//   if (newEvent) {
//     refreshLogs();
//   }
// });

async function loadLogs(page: number = 1) {
  isLoading.value = true;
  try {
    const response = await gateService.getLogs({
      page,
      pageSize: pageSize.value
    });

    logs.value = response.logs;
    currentPage.value = response.page;
    totalCount.value = response.totalCount;
  } catch (error) {
    console.error('Erro ao carregar logs:', error);
  } finally {
    isLoading.value = false;
  }
}

function refreshLogs() {
  loadLogs(currentPage.value);
}

function goToPage(page: number) {
  if (page >= 1 && page <= totalPages.value) {
    loadLogs(page);
  }
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  }).format(date);
}

function getActionIcon(action: string): string {
  switch (action) {
    case 'opened':
      return '✅';
    case 'denied':
      return '🚫';
    case 'attempted':
      return '⚠️';
    default:
      return '❓';
  }
}

function getActionText(action: string): string {
  switch (action) {
    case 'opened':
      return 'Aberto';
    case 'denied':
      return 'Negado';
    case 'attempted':
      return 'Tentativa';
    default:
      return action;
  }
}

function getActionClass(action: string): string {
  switch (action) {
    case 'opened':
      return 'action-success';
    case 'denied':
      return 'action-error';
    case 'attempted':
      return 'action-warning';
    default:
      return '';
  }
}

function getRowClass(action: string): string {
  return `row-${action}`;
}

onMounted(() => {
  loadLogs();
});
</script>

<style scoped>
.gate-log-list {
  width: 100%;
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 1.5rem;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.header h2 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
}

.btn-refresh {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

.btn-refresh:hover:not(:disabled) {
  background: #2563eb;
}

.btn-refresh:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.icon {
  width: 1.25rem;
  height: 1.25rem;
}

.loading,
.empty {
  text-align: center;
  padding: 3rem;
  color: #6b7280;
}

.empty-icon {
  width: 4rem;
  height: 4rem;
  margin: 0 auto 1rem;
  color: #d1d5db;
}

.table-container {
  overflow-x: auto;
}

.logs-table {
  width: 100%;
  border-collapse: collapse;
}

.logs-table thead {
  background: #f9fafb;
  border-bottom: 2px solid #e5e7eb;
}

.logs-table th {
  padding: 0.75rem 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  text-transform: uppercase;
}

.logs-table tbody tr {
  border-bottom: 1px solid #e5e7eb;
  transition: background 0.15s;
}

.logs-table tbody tr:hover {
  background: #f9fafb;
}

.logs-table td {
  padding: 1rem;
  color: #1f2937;
}

.extension {
  font-weight: 600;
  font-family: monospace;
}

.ip {
  font-family: monospace;
  color: #6b7280;
}

.action-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
}

.action-success {
  background: #d1fae5;
  color: #065f46;
}

.action-error {
  background: #fee2e2;
  color: #991b1b;
}

.action-warning {
  background: #fef3c7;
  color: #92400e;
}

.pagination {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

.btn-page {
  padding: 0.5rem 1rem;
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  cursor: pointer;
  font-weight: 500;
  color: #374151;
  transition: all 0.2s;
}

.btn-page:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #9ca3af;
}

.btn-page:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-info {
  color: #6b7280;
  font-size: 0.875rem;
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
