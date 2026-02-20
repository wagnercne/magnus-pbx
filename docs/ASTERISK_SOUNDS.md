# 🔊 Sons do Asterisk - Magnus PBX

## 📦 Sons Incluídos no Container

### ✅ Sons PT-BR (Português Brasileiro)

Os sons em português já vêm **embutidos no container** durante o build:

**Fonte:** [issabel_sounds_pt_BR](https://github.com/marcelsavegnago/issabel_sounds_pt_BR) by Marcel Savegnago

**Localização no container:**
```
/var/lib/asterisk/sounds/pt_BR/
```

**Instalação:** Automática via Dockerfile (linhas 44-47)

### 📋 Sons Disponíveis

Os seguintes prompts estão disponíveis em PT-BR:

- ✅ Mensagens de correio de voz
- ✅ Números (0-9, 10, 20, 30, etc)
- ✅ Dias da semana, meses
- ✅ Status de chamadas (ocupado, desligou, etc)
- ✅ Prompts do sistema (digite, pressione, aguarde)
- ✅ Mensagens de erro
- ✅ Tons de progresso

### 🎯 Configuração no dialplan

```ini
; extensions.conf ou extensions-*.conf
[ctx-belavista]
exten => *97,1,NoOp(Voicemail PT-BR)
 same => n,Set(CHANNEL(language)=pt_BR)    ; ← Define idioma
 same => n,VoiceMailMain(${CALLERID(num)}@belavista)
 same => n,Hangup()

; Alternativa: Definir idioma globalmente
[general]
language=pt_BR

; Ou por endpoint no pjsip.conf
[1001@belavista](endpoint-template)
language=pt_BR
```

### 🔍 Verificar Sons Instalados

```bash
# Listar sons PT-BR no container
docker compose exec asterisk-magnus ls -la /var/lib/asterisk/sounds/pt_BR/

# Ver número de arquivos
docker compose exec asterisk-magnus find /var/lib/asterisk/sounds/pt_BR/ -type f | wc -l

# Testar um som específico
docker compose exec asterisk-magnus asterisk -rx "core show file formats"
```

---

## 🎨 Sons Customizados (Opcional)

Se você quiser adicionar sons **customizados** além dos PT-BR padrão, temos 3 opções:

### ✅ Opção 1: Via Volume Mount (RECOMENDADO - JÁ CONFIGURADO!)

**O volume já está montado no `docker-compose.yml`:**

```yaml
# docker-compose.yml (linha ~30)
services:
  asterisk-magnus:
    volumes:
      - ./asterisk_etc:/etc/asterisk
      - ./asterisk_logs:/var/log/asterisk
      - ./asterisk_recordings:/var/spool/asterisk/monitor
      - ./custom_sounds:/var/lib/asterisk/sounds/custom  # ✅ Já configurado!
```

**Para usar:**

1. A pasta `custom_sounds/` já existe no projeto (com README.md completo)
2. Adicione seus arquivos de áudio:
```bash
# Exemplo: voz masculina PT-BR
mkdir -p custom_sounds/pt_BR_male/voicemail
cp vozes-masculinas/*.gsm custom_sounds/pt_BR_male/voicemail/

# Exemplo: sons da empresa
mkdir -p custom_sounds/minha_empresa
cp boas-vindas.{gsm,ulaw,opus} custom_sounds/minha_empresa/
```

3. Use no dialplan:
```conf
[mainmenu]
exten => s,1,Playback(custom/minha_empresa/boas-vindas)

; Ou trocar voz feminina por masculina:
exten => *97,1,Set(CHANNEL(language)=custom/pt_BR_male)
 same => n,VoiceMailMain()
```

📖 **Veja documentação completa em:** [custom_sounds/README.md](../custom_sounds/README.md)

### Opção 2: Durante o Build (Produção)

```dockerfile
# Adicionar no Dockerfile
COPY custom_sounds/ /var/lib/asterisk/sounds/custom/
RUN chown -R asterisk:asterisk /var/lib/asterisk/sounds/custom
```

### Opção 3: Upload Manual

```bash
# 1. Entrar no container
docker compose exec -u root asterisk-magnus bash

# 2. Criar pasta
mkdir -p /var/lib/asterisk/sounds/custom

# 3. Upload de fora do container
docker compose cp meu_som.wav asterisk-magnus:/var/lib/asterisk/sounds/custom/

# 4. Ajustar permissões
docker compose exec -u root asterisk-magnus chown -R asterisk:asterisk /var/lib/asterisk/sounds/custom
```

---

## 🎵 Formatos de Áudio Suportados

| Formato | Codec | Uso Recomendado |
|---------|-------|-----------------|
| **.gsm** | GSM | Telefonia tradicional (economia de espaço) |
| **.ulaw** | μ-law | Telefonia EUA/Japão |
| **.alaw** | A-law | Telefonia Europa/Brasil |
| **.wav** | PCM 16bit 8kHz | Desenvolvimento/edição |
| **.opus** | Opus | WebRTC (melhor qualidade) |
| **.sln** | Signed Linear | Processamento interno |

### 🔄 Converter Sons

```bash
# Converter WAV para GSM (economia de espaço)
sox input.wav -r 8000 -c 1 output.gsm

# Converter para múltiplos formatos
for format in gsm ulaw alaw; do
    sox input.wav -r 8000 -c 1 output.$format
done

# No container (se sox instalado)
docker compose exec asterisk-magnus sox /tmp/meu_som.wav -r 8000 -c 1 /var/lib/asterisk/sounds/custom/meu_som.gsm
```

---

## 📝 Usar Sons no Dialplan

### Som PT-BR Padrão

```ini
exten => 100,1,Answer()
 same => n,Playback(pt_BR/digits/1)          ; "um"
 same => n,Playback(pt_BR/vm-goodbye)        ; "até logo"
 same => n,Hangup()
```

### Som Customizado

```ini
exten => 101,1,Answer()
 same => n,Playback(custom/bem_vindo)        ; sem extensão!
 same => n,Hangup()

; Asterisk escolhe automaticamente o melhor formato
; Se existir: bem_vindo.gsm, bem_vindo.ulaw, bem_vindo.wav
; Ele usa o mais compatível com o codec da chamada
```

### TTS (Text-to-Speech) - Futuro

```ini
; Requer festival ou Google TTS
exten => 102,1,Answer()
 same => n,Festival(Bem-vindo ao Magnus PBX)
 same => n,Hangup()
```

---

## 🎬 Gravar Prompts Customizados

### Método 1: Record Application

```ini
; Permite gravar via telefone
exten => *555,1,Answer()
 same => n,Wait(1)
 same => n,Playback(beep)
 same => n,Record(custom/meu_prompt.gsm,3,60)  ; 3s silêncio, 60s max
 same => n,Wait(1)
 same => n,Playback(custom/meu_prompt)         ; Reproduz gravado
 same => n,Hangup()
```

### Método 2: Gravação Profissional

1. Gravar com Audacity/Adobe Audition
2. Exportar como WAV mono 8kHz 16bit
3. Converter para múltiplos formatos
4. Upload para container

---

## 🔍 Troubleshooting

### Som não toca

```bash
# 1. Verificar arquivo existe
docker compose exec asterisk-magnus ls -la /var/lib/asterisk/sounds/pt_BR/digits/

# 2. Ver formato do arquivo
docker compose exec asterisk-magnus file /var/lib/asterisk/sounds/pt_BR/digits/1.gsm

# 3. Ver logs do Asterisk
docker compose logs asterisk-magnus | grep -i "playback"

# 4. Testar manualmente via CLI
docker compose exec asterisk-magnus asterisk -rx "originate Local/100@ctx-belavista application Playback pt_BR/digits/1"
```

### Codec incompatível

```ini
; Transcodificar automaticamente
[ctx-belavista]
exten => 100,1,Answer()
 same => n,Set(CHANNEL(codec)=ulaw)    ; Forçar codec
 same => n,Playback(pt_BR/digits/1)
 same => n,Hangup()
```

### Som cortado/robotizado

- ✅ Verificar taxa de amostragem: deve ser 8000 Hz
- ✅ Verificar canais: deve ser mono (1 canal)
- ✅ Verificar formato: GSM, ulaw, alaw preferíveis

---

## 📚 Referências

- [Asterisk Sound Files](https://wiki.asterisk.org/wiki/display/AST/Sound+Prompts)
- [issabel_sounds_pt_BR](https://github.com/marcelsavegnago/issabel_sounds_pt_BR)
- [Digium Sound Packages](https://www.digium.com/products/telephony-apps/asterisk-sound-packages)

---

## ✅ Resumo

- ✅ **Sons PT-BR já incluídos** no container (nada a fazer)
- ✅ Localização: `/var/lib/asterisk/sounds/pt_BR/`
- ✅ Ativar: `Set(CHANNEL(language)=pt_BR)` no dialplan
- ⏭️ Sons customizados são opcionais (via volume mount ou COPY)
- 🎯 Formatos recomendados: GSM (economia) ou Opus (qualidade)

**Você já tem tudo pronto para usar voicemail, IVR e prompts em português!** 🇧🇷
