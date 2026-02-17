<template>
  <div class="open-gate-button">
    <button
      @click="handleOpenGate"
      :disabled="isLoading || !canOpen"
      :class="buttonClasses"
      class="btn-open-gate"
    >
      <svg
        v-if="!isLoading"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="icon"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M13.5 10.5V6.75a4.5 4.5 0 119 0v3.75M3.75 21.75h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"
        />
      </svg>
      <svg
        v-else
        class="icon animate-spin"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path
          class="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        ></path>
      </svg>
      <span>{{ buttonText }}</span>
    </button>

    <!-- Mensagem de feedback -->
    <Transition name="fade">
      <div v-if="message" :class="messageClasses" class="message">
        {{ message }}
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { gateService } from '@/services/gateService';
import { useAuthStore } from '@/stores/auth';

const authStore = useAuthStore();

const isLoading = ref(false);
const message = ref('');
const messageType = ref<'success' | 'error' | null>(null);

const canOpen = computed(() => authStore.userInfo?.canOpenGate ?? false);

const buttonText = computed(() => {
  if (isLoading.value) return 'Abrindo...';
  if (!canOpen.value) return 'Sem Permissão';
  return 'Abrir Portão';
});

const buttonClasses = computed(() => ({
  'btn-disabled': !canOpen.value || isLoading.value,
  'btn-enabled': canOpen.value && !isLoading.value
}));

const messageClasses = computed(() => ({
  'message-success': messageType.value === 'success',
  'message-error': messageType.value === 'error'
}));

async function handleOpenGate() {
  if (!canOpen.value || isLoading.value) return;

  isLoading.value = true;
  message.value = '';
  messageType.value = null;

  try {
    const result = await gateService.openGate();

    if (result.success) {
      message.value = '✅ Portão aberto com sucesso!';
      messageType.value = 'success';
    } else {
      message.value = `❌ ${result.message || 'Erro ao abrir portão'}`;
      messageType.value = 'error';
    }
  } catch (error: any) {
    console.error('Erro ao abrir portão:', error);

    if (error.response?.status === 403) {
      message.value = '🚫 Sem permissão para abrir o portão';
    } else if (error.response?.status === 401) {
      message.value = '🔒 Sessão expirada, faça login novamente';
    } else {
      message.value = '❌ Erro ao conectar com o servidor';
    }

    messageType.value = 'error';
  } finally {
    isLoading.value = false;

    // Limpa mensagem após 3 segundos
    setTimeout(() => {
      message.value = '';
      messageType.value = null;
    }, 3000);
  }
}
</script>

<style scoped>
.open-gate-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.btn-open-gate {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 2rem;
  font-size: 1.125rem;
  font-weight: 600;
  border-radius: 0.75rem;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.btn-enabled {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
}

.btn-enabled:hover {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  box-shadow: 0 6px 12px rgba(16, 185, 129, 0.4);
  transform: translateY(-2px);
}

.btn-enabled:active {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);
}

.btn-disabled {
  background: #d1d5db;
  color: #6b7280;
  cursor: not-allowed;
  opacity: 0.6;
}

.icon {
  width: 1.5rem;
  height: 1.5rem;
}

.message {
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 500;
  text-align: center;
}

.message-success {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #10b981;
}

.message-error {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #ef4444;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
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
