# 🔄 Sincronização Windows → Linux VM

**Contexto:** Você desenvolve no Windows mas o Asterisk roda em VM Linux.

Este guia explica como sincronizar os arquivos do dialplan modular.

---

## 📦 Arquivos que Precisam Estar na VM

### **Dialplan Modular (5 arquivos):**

```
asterisk_etc/
├── extensions-modular.conf    ← Arquivo principal (master)
├── extensions-features.conf   ← Feature codes (*43, *97, *500)
├── routing.conf                ← Lógica de discagem
└── tenants.conf                ← Contextos dos tenants

scripts/
└── ativar-dialplan-modular.sh ← Script de ativação
```

**Tamanho total:** ~15 KB (arquivos pequenos)

---

## 🚀 Opção 1: Script Automático (Recomendado)

### **No Windows:**

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Verificar arquivos e gerar comandos
.\scripts\copiar-para-vm.ps1

# OU gerar script SCP (se tiver SSH)
.\scripts\copiar-para-vm.ps1 `
  -VMUser "seu_usuario" `
  -VMHost "192.168.1.100" `
  -VMPath "/srv/magnus-pbx"
```

O script irá:
- ✅ Verificar se os 5 arquivos existem
- ✅ Mostrar tamanho dos arquivos
- ✅ Gerar comandos para copiar
- ✅ Criar script SCP (se parâmetros fornecidos)

---

## 🔧 Opção 2: Git (Melhor para Equipes)

### **No Windows:**

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Adicionar arquivos
git add asterisk_etc/extensions-modular.conf
git add asterisk_etc/extensions-features.conf
git add asterisk_etc/routing.conf
git add asterisk_etc/tenants.conf
git add scripts/ativar-dialplan-modular.sh

# Commit
git commit -m "feat: Adicionar dialplan modular separado por responsabilidade"

# Push
git push origin main
```

### **Na VM Linux:**

```bash
cd /srv/magnus-pbx  # Ou seu caminho
git pull origin main
```

**Vantagens:**
- ✅ Histórico de mudanças
- ✅ Fácil reverter se der problema
- ✅ Sincroniza tudo automaticamente
- ✅ Ótimo para trabalho em equipe

---

## 📡 Opção 3: SCP (Via SSH)

### **Pré-requisitos:**
- SSH habilitado na VM
- Conhecer IP da VM
- Ter usuário com permissão

### **No Windows (WSL ou Git Bash):**

```bash
# Definir variáveis
VM_USER="seu_usuario"
VM_HOST="192.168.1.100"
VM_PATH="/srv/magnus-pbx"

# Copiar arquivos
scp asterisk_etc/extensions-modular.conf ${VM_USER}@${VM_HOST}:${VM_PATH}/asterisk_etc/
scp asterisk_etc/extensions-features.conf ${VM_USER}@${VM_HOST}:${VM_PATH}/asterisk_etc/
scp asterisk_etc/routing.conf ${VM_USER}@${VM_HOST}:${VM_PATH}/asterisk_etc/
scp asterisk_etc/tenants.conf ${VM_USER}@${VM_HOST}:${VM_PATH}/asterisk_etc/
scp scripts/ativar-dialplan-modular.sh ${VM_USER}@${VM_HOST}:${VM_PATH}/scripts/
```

**OU use o script gerado:**

```bash
# Se gerou com copiar-para-vm.ps1
bash copiar-scp.sh
```

---

## 🌐 Opção 4: Compartilhamento de Rede (SMB/CIFS)

### **Configurar compartilhamento na VM:**

```bash
# Na VM Linux
sudo apt install samba
sudo mkdir -p /srv/magnus-pbx/shared
sudo chmod 777 /srv/magnus-pbx/shared

# Configurar Samba (simplificado)
sudo nano /etc/samba/smb.conf
```

Adicionar:
```ini
[magnus]
path = /srv/magnus-pbx
writable = yes
guest ok = yes
```

```bash
sudo systemctl restart smbd
```

### **No Windows:**

```
\\192.168.1.100\magnus
```

Copiar e colar arquivos manualmente.

---

## ✍️ Opção 5: Edição Manual (Emergências)

Se nenhum método acima funcionar, copie e cole manualmente:

### **No Windows:**

```powershell
# Ver conteúdo do arquivo
Get-Content asterisk_etc\extensions-modular.conf
```

### **Na VM Linux:**

```bash
# Criar/editar arquivo
nano /srv/magnus-pbx/asterisk_etc/extensions-modular.conf

# Cole o conteúdo (Ctrl+Shift+V)
# Salvar: Ctrl+O, Enter, Ctrl+X
```

Repita para os 5 arquivos.

---

## 🎯 Após Copiar os Arquivos

### **Na VM Linux:**

```bash
cd /srv/magnus-pbx  # Ou seu caminho

# 1. Verificar se arquivos foram copiados
ls -lh asterisk_etc/extensions-*.conf asterisk_etc/routing.conf asterisk_etc/tenants.conf
ls -lh scripts/ativar-dialplan-modular.sh

# 2. Dar permissão de execução
chmod +x scripts/ativar-dialplan-modular.sh

# 3. Executar script de ativação
./scripts/ativar-dialplan-modular.sh
```

O script fará automaticamente:
1. ✅ Backup do `extensions.conf` atual
2. ✅ Ativar dialplan modular
3. ✅ Reiniciar Asterisk
4. ✅ Validar se carregou

---

## 🔍 Validação

Após ativação, confirme que funcionou:

```bash
# Contextos carregados
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep ctx-

# Features funcionando
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

# Sub-rotinas carregadas
docker compose exec asterisk-magnus asterisk -rx "dialplan show s@open-gate"
```

---

## 🆘 Troubleshooting

### **Problema: Arquivos não aparecem na VM**

```bash
# Verificar se Docker está montando volume corretamente
docker compose exec asterisk-magnus ls -lh /etc/asterisk/extensions*.conf
```

### **Problema: Permissão negada no SCP**

```bash
# Na VM, ajustar permissões
sudo chown -R seu_usuario:seu_usuario /srv/magnus-pbx
```

### **Problema: SSH não conecta**

```bash
# Verificar IP da VM
ip addr show

# Testar conexão
ping 192.168.1.100
telnet 192.168.1.100 22
```

---

## 📊 Comparação de Métodos

| Método | Velocidade | Facilidade | Requer | Melhor Para |
|--------|-----------|-----------|--------|------------|
| **Git** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Git configurado | Desenvolvimento contínuo |
| **SCP** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | SSH habilitado | Cópias rápidas |
| **Script PS1** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | PowerShell | Windows users |
| **SMB/CIFS** | ⭐⭐⭐ | ⭐⭐⭐⭐ | Samba instalado | Arrastar e soltar |
| **Manual** | ⭐ | ⭐⭐ | Nada | Emergências |

---

## 💡 Recomendação

**Para Desenvolvimento Contínuo:**
```
Use Git → Mais profissional e rastreável
```

**Para Testes Rápidos:**
```
Use o script PowerShell → Automatizado e seguro
```

**Para Deploy em Produção:**
```
Use CI/CD (GitHub Actions, GitLab CI) → Automatizado e auditável
```

---

## 🔗 Próximo Passo

Após sincronizar e ativar, veja:
- [DIALPLAN_QUAL_USAR.md](DIALPLAN_QUAL_USAR.md) - Comparação modular vs monolítico
- [COMO_INICIAR.md](COMO_INICIAR.md) - Validação completa do sistema
- [../scripts/README.md](../scripts/README.md) - Documentação de todos os scripts
