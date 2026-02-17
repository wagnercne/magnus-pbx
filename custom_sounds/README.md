# 🎵 Sons Customizados - MAGNUS PBX

Esta pasta é montada em `/var/lib/asterisk/sounds/custom/` dentro do container Asterisk.

## 📂 Objetivo

Permitir **customização de prompts de áudio** sem precisar rebuildar a imagem Docker:

✅ **Trocar voz feminina por masculina** nos prompts PT-BR  
✅ **Adicionar outros idiomas** (EN, ES, FR, etc)  
✅ **Substituir sons padrão** por versões personalizadas  
✅ **Criar prompts específicos** do negócio (nome da empresa, produtos, etc)

---

## 🎯 Como Usar

### 1. Adicionar Sons Customizados

Coloque seus arquivos de áudio aqui seguindo esta estrutura:

```
custom_sounds/
├── pt_BR/                    # Sobrescrever sons PT-BR padrão
│   ├── voicemail/
│   │   └── vm-intro.gsm     # Substitui mensagem de voicemail
│   └── digits/
│       └── 1.gsm            # Substitui número "um"
│
├── pt_BR_male/               # Versão masculina dos prompts
│   ├── voicemail/
│   └── digits/
│
├── en/                       # Inglês
│   └── welcome.gsm
│
└── empresa/                  # Sons específicos da empresa
    ├── boas-vindas.gsm
    └── menu-principal.gsm
```

### 2. Usar no Dialplan

**Exemplo 1: Som customizado específico**
```conf
[mainmenu]
exten => s,1,Answer()
 same => n,Playback(custom/empresa/boas-vindas)  ; /var/lib/asterisk/sounds/custom/empresa/boas-vindas.gsm
 same => n,Hangup()
```

**Exemplo 2: Trocar idioma para versão customizada**
```conf
[voicemail-male]
exten => *97,1,Answer()
 same => n,Set(CHANNEL(language)=custom/pt_BR_male)  ; Usa versão masculina
 same => n,VoiceMailMain()
 same => n,Hangup()
```

**Exemplo 3: Fallback para sons padrão**
```conf
[welcome]
exten => s,1,TryExec(Playback(custom/empresa/welcome))  ; Tenta custom primeiro
 same => n,Playback(pt_BR/vm-intro)                      ; Se falhar, usa padrão
```

---

## 🎙️ Formatos Suportados

| Formato | Tamanho | Qualidade | Uso Recomendado |
|---------|---------|-----------|-----------------|
| **GSM** | 1.6 KB/s | Baixa | Prompts de sistema (economia) |
| **ulaw** | 64 KB/s | Média | SIP tradicional |
| **alaw** | 64 KB/s | Média | Telefonia europeia |
| **opus** | 16-48 KB/s | Alta | WebRTC (recomendado) |
| **WAV** | ~1.4 MB/s | Máxima | Edição/conversão (não usar em produção) |

**⚠️ Recomendação:** Sempre forneça múltiplos formatos para compatibilidade:
```
custom_sounds/empresa/
├── boas-vindas.gsm    # Para economia de banda
├── boas-vindas.ulaw   # Para SIP tradicional
└── boas-vindas.opus   # Para WebRTC
```

---

## 🔧 Converter Sons para Asterisk

### Método 1: sox (Recomendado)
```bash
# WAV → GSM
sox input.wav -r 8000 -c 1 -t gsm output.gsm

# WAV → ulaw
sox input.wav -r 8000 -c 1 -e u-law output.ulaw

# WAV → alaw
sox input.wav -r 8000 -c 1 -e a-law output.alaw

# WAV → opus (WebRTC)
ffmpeg -i input.wav -ar 48000 -ac 1 -b:a 32k output.opus
```

### Método 2: ffmpeg
```bash
# WAV → GSM
ffmpeg -i input.wav -ar 8000 -ac 1 -codec:a gsm output.gsm

# WAV → ulaw
ffmpeg -i input.wav -ar 8000 -ac 1 -codec:a pcm_mulaw output.ulaw
```

### Método 3: Usar Asterisk CLI (dentro do container)
```bash
# Entrar no container
docker compose exec asterisk-magnus bash

# Converter usando Asterisk
asterisk -rx "file convert /tmp/input.wav /var/lib/asterisk/sounds/custom/output.gsm"
```

---

## 📝 Onde Obter Sons Profissionais

### Opções Gratuitas
- **issabel_sounds_pt_BR** (Marcel Savegnago): https://github.com/marcelsavegnago/issabel_sounds_pt_BR
- **Asterisk Sounds PT-BR** (Digium): https://www.asterisk.org/community/downloads/
- **Gravação própria** via dialplan `*555` (ver seção abaixo)

### Opções Pagas (Qualidade Profissional)
- **Locaweb Sounds**: Voz profissional PT-BR
- **VoiceOverBrasil**: Gravação customizada
- **Elevenlabs**: IA com vozes naturais (PT-BR, EN, ES, etc)
- **Google TTS / Amazon Polly**: Síntese de voz via API

---

## 🎤 Gravar Prompts via Telefone

**dialplan em `extensions.conf`:**
```conf
[record-prompts]
exten => *555,1,Answer()
 same => n,Playback(custom/pt_BR/beep)  ; Aviso sonoro
 same => n,Read(filename,5000)           ; Digite o nome do arquivo
 same => n,Record(custom/empresa/${filename}.gsm,3,300)  ; Grava até 5min
 same => n,Playback(custom/empresa/${filename})          ; Reproduz
 same => n,Hangup()
```

**Como usar:**
1. Disque `*555`
2. Digite nome do arquivo (ex: 1234)
3. Fale o prompt
4. Pressione `#` para finalizar
5. Arquivo salvo em `/var/lib/asterisk/sounds/custom/empresa/1234.gsm`

---

## ✅ Aplicar Mudanças

Após adicionar/modificar sons:

```bash
# 1. Verificar arquivos no container
docker compose exec asterisk-magnus ls -lh /var/lib/asterisk/sounds/custom/

# 2. Testar som via CLI
docker compose exec asterisk-magnus asterisk -rx "core show sounds custom" | head -20

# 3. Recarregar configurações (se mudou dialplan)
docker compose exec asterisk-magnus asterisk -rx "dialplan reload"

# 4. Testar via telefone
# Disque para ramal de teste que usa o som customizado
```

**⚠️ Não precisa reiniciar container** - os sons são lidos do volume montado em tempo real.

---

## 🔍 Troubleshooting

### Som não toca
```bash
# Verificar se arquivo existe
docker compose exec asterisk-magnus ls -la /var/lib/asterisk/sounds/custom/empresa/

# Verificar permissões
docker compose exec asterisk-magnus ls -lh /var/lib/asterisk/sounds/custom/
# Deve ser legível pelo usuário asterisk (UID 1000)

# Testar manualmente
docker compose exec asterisk-magnus asterisk -rx "originate Local/1001@default application Playback custom/empresa/boas-vindas"
```

### Qualidade ruim
```bash
# Verificar sample rate (deve ser 8000 Hz)
ffprobe custom_sounds/empresa/arquivo.gsm

# Reconverter se necessário
sox arquivo.wav -r 8000 -c 1 -t gsm arquivo.gsm
```

### Codec não suportado
```bash
# Listar codecs disponíveis
docker compose exec asterisk-magnus asterisk -rx "core show codecs"

# Converter para formato compatível
ffmpeg -i input.mp3 -ar 8000 -ac 1 -codec:a pcm_mulaw output.ulaw
```

---

## 📊 Exemplos Práticos

### Caso 1: Trocar voz feminina por masculina (PT-BR)

**Problema:** Sons padrão PT-BR usam voz feminina, cliente quer masculina.

**Solução:**
1. Baixar pack masculino (ou gravar/comprar)
2. Colocar em `custom_sounds/pt_BR_male/`
3. Alterar dialplan:
```conf
[default]
exten => s,1,Answer()
 same => n,Set(CHANNEL(language)=custom/pt_BR_male)  ; Força voz masculina
 same => n,VoiceMailMain()
```

### Caso 2: Adicionar Inglês

**Solução:**
1. Baixar Asterisk sounds EN-US
2. Extrair para `custom_sounds/en/`
3. Usar no dialplan:
```conf
[english-menu]
exten => 9,1,Set(CHANNEL(language)=custom/en)
 same => n,Background(main-menu)
```

### Caso 3: Prompts específicos de empresa

**Solução:**
1. Gravar mensagens: "Bem-vindo à ACME Corp", "Departamento Financeiro", etc
2. Converter para .gsm/.ulaw/.opus
3. Colocar em `custom_sounds/acme/`
4. Usar diretamente:
```conf
[acme-greeting]
exten => s,1,Playback(custom/acme/welcome)
 same => n,Background(custom/acme/main-menu)
```

---

## 📚 Estrutura Recomendada

```
custom_sounds/
├── README.md                      # Este arquivo
├── .gitkeep                       # Mantém pasta no Git
│
├── pt_BR_male/                    # Voz masculina PT-BR
│   ├── voicemail/
│   ├── digits/
│   └── letters/
│
├── en/                            # Inglês
│   └── ...
│
├── es/                            # Espanhol
│   └── ...
│
└── tenants/                       # Sons por tenant
    ├── belavista/
    │   ├── welcome.gsm
    │   └── goodbye.gsm
    ├── acme/
    │   └── menu.gsm
    └── techno/
        └── greeting.gsm
```

---

## 🎯 Conclusão

Com esta estrutura você pode:

✅ **Personalizar** qualquer prompt do sistema  
✅ **Multi-idioma** sem rebuildar imagem  
✅ **Multi-tenant** com sons diferentes por empresa  
✅ **Testar** rapidamente novas versões  
✅ **Manter** sons no Git (se desejar) ou .gitignore (se privados)

**Montado em:** `/var/lib/asterisk/sounds/custom/` (dentro do container)  
**Acessível via:** `Playback(custom/caminho/arquivo)` no dialplan
