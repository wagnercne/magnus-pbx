import { ref, onMounted, onUnmounted } from 'vue';
import { HubConnectionBuilder, HubConnection, LogLevel } from '@microsoft/signalr';
import { useAuthStore } from '@/stores/auth';

const signalrHubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || '/hubs/asterisk';

export interface GateEvent {
  extension: string;
  tenantSlug: string;
  action: string;
  timestamp: string;
}

export function useSignalR() {
  const connection = ref<HubConnection | null>(null);
  const isConnected = ref(false);
  const lastGateEvent = ref<GateEvent | null>(null);

  const authStore = useAuthStore();

  async function startConnection() {
    if (!authStore.token) {
      console.warn('Sem token JWT, não é possível conectar ao SignalR');
      return;
    }

    try {
      // Cria conexão com autenticação via query string (configurado no Program.cs)
      connection.value = new HubConnectionBuilder()
        .withUrl(`${signalrHubUrl}?access_token=${authStore.token}`, {
          skipNegotiation: false,
          withCredentials: false
        })
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .configureLogging(LogLevel.Information)
        .build();

      // Event handlers
      connection.value.on('GateOpened', (event: GateEvent) => {
        console.log('🚪 Portão aberto:', event);
        lastGateEvent.value = event;
      });

      connection.value.on('GateDenied', (event: GateEvent) => {
        console.warn('🚫 Abertura de portão negada:', event);
        lastGateEvent.value = event;
      });

      connection.value.on('NewCall', (data: any) => {
        console.log('📞 Nova chamada:', data);
      });

      connection.value.onreconnecting((error) => {
        console.warn('🔄 SignalR reconectando...', error);
        isConnected.value = false;
      });

      connection.value.onreconnected((connectionId) => {
        console.log('✅ SignalR reconectado:', connectionId);
        isConnected.value = true;
      });

      connection.value.onclose((error) => {
        console.error('❌ SignalR desconectado:', error);
        isConnected.value = false;
      });

      await connection.value.start();
      isConnected.value = true;
      console.log('✅ SignalR conectado');
    } catch (error) {
      console.error('Erro ao conectar SignalR:', error);
      isConnected.value = false;
    }
  }

  async function stopConnection() {
    if (connection.value) {
      await connection.value.stop();
      connection.value = null;
      isConnected.value = false;
      console.log('SignalR desconectado');
    }
  }

  // Lifecycle hooks automáticos
  onMounted(() => {
    if (authStore.isAuthenticated) {
      startConnection();
    }
  });

  onUnmounted(() => {
    stopConnection();
  });

  return {
    connection,
    isConnected,
    lastGateEvent,
    startConnection,
    stopConnection
  };
}
