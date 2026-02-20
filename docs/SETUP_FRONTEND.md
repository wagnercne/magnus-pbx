# Frontend Vue 3 + TypeScript + Vite

## Criar Projeto

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Opção 1: Criar projeto novo
npm create vite@latest frontend -- --template vue-ts

# Opção 2: Se a pasta já existe
cd frontend
npm create vite@latest . -- --template vue-ts
```

## Instalar Dependências

```powershell
cd frontend

# Instalar dependências base
npm install

# Vue Router
npm install vue-router@4

# Pinia (state management)
npm install pinia

# Axios (HTTP client)
npm install axios

# SignalR (realtime)
npm install @microsoft/signalr

# JsSIP (WebRTC)
npm install jssip
npm install --save-dev @types/jssip

# TailwindCSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# HeadlessUI (componentes acessíveis)
npm install @headlessui/vue

# Heroicons (ícones)
npm install @heroicons/vue

# Date utilities
npm install date-fns

# Toast notifications
npm install vue-toastification@next
```

## Configurar TailwindCSS

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        }
      }
    },
  },
  plugins: [],
}
```

## Estrutura de Diretórios

```
frontend/
├── public/
├── src/
│   ├── assets/
│   │   └── logo.svg
│   │
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.vue
│   │   │   ├── Input.vue
│   │   │   ├── Modal.vue
│   │   │   └── Loading.vue
│   │   │
│   │   ├── admin/
│   │   │   ├── Dashboard.vue
│   │   │   ├── TenantList.vue
│   │   │   ├── ExtensionList.vue
│   │   │   └── GateLogList.vue
│   │   │
│   │   ├── portaria/
│   │   │   ├── PortariaInterface.vue
│   │   │   ├── VideoPorteiro.vue
│   │   │   └── OpenGateButton.vue
│   │   │
│   │   └── morador/
│   │       ├── MoradorHome.vue
│   │       ├── GateControl.vue
│   │       └── CallHistory.vue
│   │
│   ├── composables/
│   │   ├── useAuth.ts
│   │   ├── useSignalR.ts
│   │   ├── useWebRTC.ts
│   │   └── useAxios.ts
│   │
│   ├── router/
│   │   └── index.ts
│   │
│   ├── services/
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   ├── gateService.ts
│   │   └── signalrService.ts
│   │
│   ├── stores/
│   │   ├── auth.ts
│   │   ├── tenant.ts
│   │   └── realtime.ts
│   │
│   ├── types/
│   │   ├── auth.ts
│   │   ├── gate.ts
│   │   └── api.ts
│   │
│   ├── views/
│   │   ├── Login.vue
│   │   ├── AdminDashboard.vue
│   │   ├── PortariaView.vue
│   │   └── MoradorView.vue
│   │
│   ├── App.vue
│   ├── main.ts
│   └── style.css
│
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## Scripts Úteis

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "type-check": "vue-tsc --noEmit"
  }
}
```

## Rodar Projeto

```powershell
# Modo desenvolvimento
npm run dev

# Build para produção
npm run build

# Preview da build
npm run preview
```

Frontend estará disponível em: http://localhost:5173
