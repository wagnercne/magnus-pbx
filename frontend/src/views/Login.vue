<template>
  <div class="login-page">
    <div class="login-shell">
      <section class="left-panel">
        <div class="brand-head">
          <div class="brand-shield" aria-hidden="true">
            <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
              <path d="M60 8L102 24V56C102 82 84 103 60 112C36 103 18 82 18 56V24L60 8Z" class="shield"/>
              <path d="M39 78V42H48L60 58L72 42H81V78H72V57L60 72L48 57V78H39Z" class="m-mark"/>
            </svg>
          </div>
          <div>
            <h1 class="brand-title">Magnus PBX</h1>
            <p class="brand-subtitle">Secure Virtual Concierge</p>
          </div>
        </div>

        <div class="welcome-block">
          <h2>Welcome Back</h2>
        </div>

        <form @submit.prevent="handleLogin" class="login-form">
          <label class="input-wrap" for="username">
            <span class="field-icon">✉</span>
            <input
              id="username"
              v-model="credentials.username"
              type="text"
              placeholder="Work Email"
              required
              autofocus
              :disabled="isLoading"
            />
          </label>

          <label class="input-wrap" for="password">
            <span class="field-icon">🔒</span>
            <input
              id="password"
              v-model="credentials.password"
              type="password"
              placeholder="Password"
              required
              :disabled="isLoading"
            />
          </label>

          <Transition name="fade">
            <div v-if="errorMessage" class="error-message">
              {{ errorMessage }}
            </div>
          </Transition>

          <button type="submit" :disabled="isLoading" class="btn-login">
            <svg
              v-if="isLoading"
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
            <span>{{ isLoading ? 'Signing in...' : 'Sign In' }}</span>
          </button>
        </form>
      </section>

      <section class="right-panel" aria-hidden="true">
        <div class="hero-overlay"></div>
        <div class="hero-logo">
          <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 12L168 37V88C168 130 139 164 100 180C61 164 32 130 32 88V37L100 12Z" class="shield"/>
            <path d="M68 132V66H82L100 90L118 66H132V132H118V90L100 114L82 90V132H68Z" class="m-mark"/>
          </svg>
          <div class="signal signal-left"></div>
          <div class="signal signal-right"></div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = useRouter();
const authStore = useAuthStore();

const credentials = reactive({
  username: '',
  password: ''
});

const isLoading = ref(false);
const errorMessage = ref('');

async function handleLogin() {
  if (isLoading.value) return;

  isLoading.value = true;
  errorMessage.value = '';

  try {
    const success = await authStore.login(credentials);

    if (success) {
      router.push('/');
    } else {
      errorMessage.value = 'Ramal ou senha incorretos';
    }
  } catch (error: any) {
    console.error('Erro no login:', error);
    
    if (error.response?.status === 401) {
      errorMessage.value = 'Ramal ou senha incorretos';
    } else if (error.response?.status === 403) {
      errorMessage.value = 'Acesso não autorizado';
    } else {
      errorMessage.value = 'Erro ao conectar com o servidor';
    }
  } finally {
    isLoading.value = false;
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 20% 20%, rgba(96, 223, 255, 0.16), transparent 42%),
    radial-gradient(circle at 85% 15%, rgba(106, 122, 255, 0.2), transparent 40%),
    #080b16;
  padding: 1.25rem;
  color: #f0f5ff;
}

.login-shell {
  width: min(1080px, 100%);
  min-height: min(680px, 92vh);
  border-radius: 24px;
  overflow: hidden;
  display: grid;
  grid-template-columns: 1fr 1fr;
  border: 1px solid rgba(113, 216, 255, 0.22);
  box-shadow: 0 28px 80px rgba(0, 0, 0, 0.45);
  background: #0b1020;
}

.left-panel {
  padding: 2.4rem 2.6rem;
  background: linear-gradient(145deg, #0f1b31 0%, #10172b 58%, #0c1323 100%);
  display: flex;
  flex-direction: column;
}

.brand-head {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.brand-shield {
  width: 68px;
  height: 68px;
  filter: drop-shadow(0 0 12px rgba(87, 220, 255, 0.65));
}

.brand-title {
  font-size: 2rem;
  line-height: 1;
  letter-spacing: 0.4px;
  margin: 0;
  font-weight: 800;
}

.brand-subtitle {
  margin: 0.35rem 0 0;
  color: #67edf8;
  font-size: 1.25rem;
}

.welcome-block {
  margin-top: 3.2rem;
  margin-bottom: 2rem;
}

.welcome-block h2 {
  margin: 0;
  font-size: clamp(2rem, 3vw, 3.2rem);
  font-weight: 750;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 0.5rem;
}

.input-wrap {
  height: 64px;
  display: flex;
  align-items: center;
  border-radius: 14px;
  border: 1px solid rgba(99, 198, 255, 0.75);
  background: rgba(9, 18, 34, 0.78);
  box-shadow: inset 0 0 0 1px rgba(170, 236, 255, 0.12);
  padding: 0 1rem;
  transition: all 0.2s;
}

.input-wrap:focus-within {
  border-color: #7edbff;
  box-shadow:
    0 0 0 3px rgba(106, 233, 255, 0.12),
    inset 0 0 0 1px rgba(170, 236, 255, 0.2);
}

.field-icon {
  width: 26px;
  text-align: center;
  margin-right: 0.8rem;
  color: #8dd8ff;
  opacity: 0.92;
  font-size: 1.05rem;
}

.input-wrap input {
  width: 100%;
  border: 0;
  outline: none;
  background: transparent;
  color: #eff6ff;
  font-size: 1.25rem;
  font-weight: 500;
}

.input-wrap input::placeholder {
  color: rgba(238, 245, 255, 0.8);
}

.input-wrap input:disabled {
  cursor: not-allowed;
  opacity: 0.75;
}

.error-message {
  padding: 0.7rem 0.8rem;
  background: rgba(255, 80, 102, 0.2);
  color: #ffd3d8;
  border-radius: 10px;
  font-size: 0.92rem;
  text-align: center;
  border: 1px solid rgba(255, 139, 153, 0.5);
}

.btn-login {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  height: 66px;
  margin-top: 0.5rem;
  background: linear-gradient(90deg, #67f0ea 0%, #4668ff 100%);
  color: #f8fbff;
  border: none;
  border-radius: 999px;
  font-size: 2rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 8px 24px rgba(74, 190, 255, 0.33);
}

.btn-login:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 12px 30px rgba(74, 190, 255, 0.4);
}

.btn-login:active:not(:disabled) {
  transform: translateY(0);
}

.btn-login:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.icon {
  width: 1.5rem;
  height: 1.5rem;
}

.right-panel {
  position: relative;
  background:
    linear-gradient(130deg, rgba(9, 15, 27, 0.8), rgba(10, 16, 30, 0.74)),
    radial-gradient(circle at 65% 35%, rgba(93, 226, 255, 0.35), transparent 35%),
    linear-gradient(160deg, #0a1325 0%, #0a1322 60%, #0b1424 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(163, 216, 255, 0.08) 1px, transparent 1px),
    linear-gradient(90deg, rgba(163, 216, 255, 0.08) 1px, transparent 1px);
  background-size: 28px 28px;
  opacity: 0.24;
}

.hero-logo {
  position: relative;
  width: min(420px, 72%);
  z-index: 1;
  filter: drop-shadow(0 0 20px rgba(89, 223, 255, 0.55));
}

.hero-logo svg {
  width: 100%;
}

.shield {
  fill: rgba(12, 30, 56, 0.72);
  stroke: #74ebff;
  stroke-width: 4;
}

.m-mark {
  fill: #81f2ff;
}

.signal {
  position: absolute;
  top: 50%;
  width: 70px;
  height: 70px;
  border: 4px solid rgba(106, 236, 255, 0.7);
  border-right: 0;
  border-top-left-radius: 999px;
  border-bottom-left-radius: 999px;
  transform: translateY(-50%);
}

.signal-left {
  left: -70px;
}

.signal-right {
  right: -70px;
  transform: translateY(-50%) rotate(180deg);
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

@media (max-width: 980px) {
  .login-shell {
    grid-template-columns: 1fr;
  }

  .right-panel {
    min-height: 280px;
    order: -1;
  }

  .left-panel {
    padding: 1.6rem;
  }

  .brand-title {
    font-size: 1.7rem;
  }

  .brand-subtitle {
    font-size: 1rem;
  }

  .welcome-block {
    margin-top: 1.8rem;
  }

  .btn-login {
    font-size: 1.4rem;
  }
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
