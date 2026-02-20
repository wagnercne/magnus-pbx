<template>
  <div class="min-h-screen bg-[#0f172a] p-4 md:p-8">
    <div class="mx-auto grid min-h-[88vh] w-full max-w-6xl overflow-hidden rounded-3xl border border-cyan-500/20 bg-slate-950/70 shadow-2xl shadow-cyan-900/20 lg:grid-cols-2">
      <section class="flex flex-col justify-center px-8 py-10 md:px-12 lg:px-14">
        <header class="mb-10 flex items-center gap-4">
          <div class="h-14 w-14 shrink-0 text-cyan-400 drop-shadow-[0_0_18px_rgba(6,182,212,0.45)]">
            <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" class="h-full w-full">
              <path d="M60 8L102 24V56C102 82 84 103 60 112C36 103 18 82 18 56V24L60 8Z" fill="rgba(34,211,238,0.12)" stroke="currentColor" stroke-width="4" />
              <path d="M40 78V42H49L60 58L71 42H80V78H71V57L60 72L49 57V78H40Z" fill="currentColor" />
            </svg>
          </div>
          <div>
            <h1 class="text-4xl font-extrabold tracking-tight text-white">Magnus PBX</h1>
            <p class="text-sm text-slate-400">Comunicação Inteligente</p>
          </div>
        </header>

        <div class="mb-8">
          <h2 class="text-3xl font-semibold text-white md:text-4xl">Bem-vindo de volta</h2>
        </div>

        <form class="space-y-4" @submit.prevent="handleLogin">
          <div>
            <label for="email" class="sr-only">E-mail de Trabalho</label>
            <div class="relative">
              <Mail class="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                id="email"
                v-model="form.email"
                type="email"
                placeholder="E-mail de Trabalho"
                autocomplete="email"
                :disabled="isLoading"
                class="h-14 w-full rounded-xl border border-slate-700 bg-slate-900/80 pl-12 pr-4 text-base text-white placeholder:text-slate-400 outline-none transition focus:border-cyan-400 focus:ring-2 focus:ring-cyan-500/60 disabled:cursor-not-allowed disabled:opacity-70"
              />
            </div>
          </div>

          <div>
            <label for="password" class="sr-only">Senha</label>
            <div class="relative">
              <Lock class="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                id="password"
                v-model="form.password"
                type="password"
                placeholder="Senha"
                autocomplete="current-password"
                :disabled="isLoading"
                class="h-14 w-full rounded-xl border border-slate-700 bg-slate-900/80 pl-12 pr-4 text-base text-white placeholder:text-slate-400 outline-none transition focus:border-cyan-400 focus:ring-2 focus:ring-cyan-500/60 disabled:cursor-not-allowed disabled:opacity-70"
              />
            </div>
          </div>

          <p v-if="validationError" class="rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
            {{ validationError }}
          </p>

          <p v-if="errorMessage" class="rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
            {{ errorMessage }}
          </p>

          <button
            type="submit"
            :disabled="isLoading"
            class="mt-3 flex h-14 w-full items-center justify-center gap-2 rounded-full bg-gradient-to-r from-cyan-500 to-blue-600 text-lg font-bold text-white transition hover:shadow-[0_0_20px_rgba(6,182,212,0.5)] disabled:cursor-not-allowed disabled:opacity-70"
          >
            <svg
              v-if="isLoading"
              class="h-5 w-5 animate-spin"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            <span>{{ isLoading ? 'Entrando...' : 'Entrar' }}</span>
          </button>
        </form>
      </section>

      <section class="relative hidden lg:block">
        <img :src="heroImage" alt="Prédio futurista Magnus PBX" class="h-full w-full object-cover" />
        <div class="absolute inset-0 bg-gradient-to-br from-slate-950/30 via-slate-950/10 to-slate-950/50" />
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { Mail, Lock } from 'lucide-vue-next';
import { useAuthStore } from '@/stores/auth';
import heroImage from '@/assets/login-right-hero.jpeg';

interface LoginForm {
  email: string;
  password: string;
}

const router = useRouter();
const authStore = useAuthStore();

const form = reactive<LoginForm>({
  email: '',
  password: ''
});

const isLoading = ref(false);
const errorMessage = ref('');
const validationError = ref('');

function validateForm(payload: LoginForm): string | null {
  if (!payload.email.trim()) return 'Informe o e-mail de trabalho.';
  if (!/^\S+@\S+\.\S+$/.test(payload.email)) return 'Informe um e-mail válido.';
  if (!payload.password.trim()) return 'Informe a senha.';
  if (payload.password.length < 4) return 'A senha deve ter ao menos 4 caracteres.';
  return null;
}

async function handleLogin() {
  if (isLoading.value) return;

  validationError.value = '';
  errorMessage.value = '';

  const validation = validateForm(form);
  if (validation) {
    validationError.value = validation;
    return;
  }

  isLoading.value = true;

  try {
    const success = await authStore.login({
      username: form.email,
      password: form.password
    });

    if (success) {
      router.push('/');
      return;
    }

    errorMessage.value = 'E-mail ou senha incorretos.';
  } catch (error: any) {
    if (error?.response?.status === 401) {
      errorMessage.value = 'E-mail ou senha incorretos.';
    } else if (error?.response?.status === 403) {
      errorMessage.value = 'Acesso não autorizado.';
    } else {
      errorMessage.value = 'Erro ao conectar com o servidor.';
    }
  } finally {
    isLoading.value = false;
  }
}
</script>
