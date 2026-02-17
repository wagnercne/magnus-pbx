import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface UserInfo {
  extension: string;
  tenantSlug: string;
  tenantName: string;
  canOpenGate: boolean;
}

export const useAuthStore = defineStore('auth', () => {
  // State
  const token = ref<string | null>(localStorage.getItem('magnus_token'));
  const userInfo = ref<UserInfo | null>(null);

  // Getters
  const isAuthenticated = computed(() => !!token.value);
  const currentExtension = computed(() => userInfo.value?.extension || null);
  const currentTenant = computed(() => userInfo.value?.tenantSlug || null);

  // Actions
  function setToken(newToken: string) {
    token.value = newToken;
    localStorage.setItem('magnus_token', newToken);
    
    // Decodifica JWT para extrair userInfo
    try {
      const payload = JSON.parse(atob(newToken.split('.')[1]));
      userInfo.value = {
        extension: payload.Extension || payload.extension,
        tenantSlug: payload.TenantSlug || payload.tenantSlug,
        tenantName: payload.TenantName || payload.tenantName || '',
        canOpenGate: payload.CanOpenGate === 'true' || payload.canOpenGate === true
      };
    } catch (e) {
      console.error('Erro ao decodificar token:', e);
    }
  }

  function logout() {
    token.value = null;
    userInfo.value = null;
    localStorage.removeItem('magnus_token');
  }

  // Login será implementado quando o AuthController estiver pronto
  async function login(credentials: LoginCredentials): Promise<boolean> {
    // TODO: Implementar chamada à API /api/auth/login
    console.warn('Login API não implementada ainda');
    
    // Mock temporário para desenvolvimento
    if (credentials.username === '1001' && credentials.password === 'senha123') {
      const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJFeHRlbnNpb24iOiIxMDAxIiwiVGVuYW50U2x1ZyI6ImJlbGF2aXN0YSIsIlRlbmFudE5hbWUiOiJCZWxhIFZpc3RhIiwiQ2FuT3BlbkdhdGUiOiJ0cnVlIn0.mock';
      setToken(mockToken);
      return true;
    }
    return false;
  }

  return {
    // State
    token,
    userInfo,
    // Getters
    isAuthenticated,
    currentExtension,
    currentTenant,
    // Actions
    setToken,
    logout,
    login
  };
});
