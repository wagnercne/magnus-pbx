import { createApp } from 'vue';
import { createPinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import App from './App.vue';
import Dashboard from './views/Dashboard.vue';
import Login from './views/Login.vue';
import { useAuthStore } from './stores/auth';
import './style.css';

// Configuração do router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Dashboard',
      component: Dashboard,
      meta: { requiresAuth: true }
    },
    {
      path: '/login',
      name: 'Login',
      component: Login,
      meta: { requiresAuth: false }
    }
  ]
});

// Guard de navegação para proteger rotas
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Rota requer autenticação mas usuário não está logado
    next('/login');
  } else if (to.path === '/login' && authStore.isAuthenticated) {
    // Usuário já está logado tentando acessar login
    next('/');
  } else {
    next();
  }
});

// Inicialização da aplicação
const app = createApp(App);
const pinia = createPinia();

app.use(pinia);
app.use(router);

app.mount('#app');
