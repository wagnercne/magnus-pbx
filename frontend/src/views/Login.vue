<template>
  <div class="login-page">
    <div class="login-shell">
      <section class="left-panel">
        <div class="brand-head">
          <img class="brand-banner" :src="headerBrand" alt="Magnus PBX" />
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
        <img class="hero-image" :src="rightHero" alt="Magnus PBX visual" />
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import rightHero from '@/assets/login-right-hero.jpeg';
import headerBrand from '@/assets/login-header-brand.png';

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
  width: 100%;
}

.brand-banner {
  width: min(500px, 100%);
  height: auto;
  display: block;
  filter: drop-shadow(0 0 10px rgba(88, 224, 255, 0.35));
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
  background: #0a1325;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(6, 10, 18, 0.15), rgba(6, 10, 18, 0.32));
  z-index: 2;
}

.hero-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
  z-index: 1;
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
