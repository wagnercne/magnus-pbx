#!/usr/bin/env pwsh
# ============================================
# COPIAR ARQUIVOS MODULAR PARA VM LINUX
# Execute no Windows para preparar arquivos
# ============================================

param(
    [string]$VMUser = "",
    [string]$VMHost = "",
    [string]$VMPath = "/srv/magnus-pbx"
)

Write-Host "=========================================="
Write-Host " COPIAR DIALPLAN MODULAR PARA VM"
Write-Host "=========================================="
Write-Host ""

# Arquivos necessários
$files = @(
    "asterisk_etc\extensions-modular.conf",
    "asterisk_etc\extensions-features.conf",
    "asterisk_etc\routing.conf",
    "asterisk_etc\tenants.conf",
    "scripts\ativar-dialplan-modular.sh"
)

Write-Host "[1/3] Verificando arquivos locais..."
$missing = 0
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file NÃO ENCONTRADO!" -ForegroundColor Red
        $missing++
    }
}

if ($missing -gt 0) {
    Write-Host ""
    Write-Host "ERRO: $missing arquivo(s) faltando!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Arquivos que serão copiados:"
Write-Host ""
foreach ($file in $files) {
    $size = (Get-Item $file).Length
    Write-Host "  📄 $file ($size bytes)"
}

Write-Host ""
Write-Host "=========================================="
Write-Host " ESCOLHA O MÉTODO DE CÓPIA"
Write-Host "=========================================="
Write-Host ""
Write-Host "Método 1: GIT (Recomendado)"
Write-Host "  git add asterisk_etc/*.conf scripts/ativar-dialplan-modular.sh"
Write-Host "  git commit -m 'Adicionar dialplan modular'"
Write-Host "  git push origin main"
Write-Host "  "
Write-Host "  # Na VM: clone primeiro (se ainda não tem o projeto)"
Write-Host "  cd /srv"
Write-Host "  git clone https://github.com/wagnercne/magnus-pbx.git"
Write-Host "  cd magnus-pbx"
Write-Host "  "
Write-Host "  # Para atualizações futuras:"
Write-Host "  cd /srv/magnus-pbx"
Write-Host "  git pull origin main"
Write-Host ""
Write-Host "Método 2: SCP (Requer SSH)"
if ($VMUser -and $VMHost) {
    Write-Host "  scp asterisk_etc/extensions-modular.conf ${VMUser}@${VMHost}:${VMPath}/asterisk_etc/"
    Write-Host "  scp asterisk_etc/extensions-features.conf ${VMUser}@${VMHost}:${VMPath}/asterisk_etc/"
    Write-Host "  scp asterisk_etc/routing.conf ${VMUser}@${VMHost}:${VMPath}/asterisk_etc/"
    Write-Host "  scp asterisk_etc/tenants.conf ${VMUser}@${VMHost}:${VMPath}/asterisk_etc/"
    Write-Host "  scp scripts/ativar-dialplan-modular.sh ${VMUser}@${VMHost}:${VMPath}/scripts/"
} else {
    Write-Host "  # Configure os parâmetros:"
    Write-Host "  .\scripts\copiar-para-vm.ps1 -VMUser 'seu_usuario' -VMHost '192.168.1.100' -VMPath '/srv/magnus-pbx'"
}
Write-Host ""
Write-Host "Método 3: COMPARTILHAMENTO DE REDE"
Write-Host "  # Monte pasta compartilhada e copie manualmente"
Write-Host ""
Write-Host "Método 4: EDITOR MANUAL NA VM"
Write-Host "  # Abra cada arquivo na VM e cole o conteúdo"
Write-Host ""

Write-Host "=========================================="
Write-Host " [3/3] PRÓXIMOS PASSOS NA VM LINUX"
Write-Host "=========================================="
Write-Host ""
Write-Host "Após copiar os arquivos, execute na VM:"
Write-Host ""
Write-Host "  cd $VMPath"
Write-Host "  chmod +x scripts/ativar-dialplan-modular.sh"
Write-Host "  ./scripts/ativar-dialplan-modular.sh"
Write-Host ""
Write-Host "O script irá:"
Write-Host "  1. Verificar se todos os arquivos estão presentes"
Write-Host "  2. Fazer backup do extensions.conf atual"
Write-Host "  3. Ativar o dialplan modular"
Write-Host "  4. Reiniciar Asterisk"
Write-Host "  5. Validar se carregou corretamente"
Write-Host ""
Write-Host "=========================================="
Write-Host " CONCLUÍDO!"
Write-Host "=========================================="
Write-Host ""

# Se parâmetros fornecidos, gerar script SCP
if ($VMUser -and $VMHost) {
    Write-Host "Gerando script SCP: copiar-scp.sh"
    $scpScript = @"
#!/bin/bash
# Script gerado automaticamente
VM_USER="$VMUser"
VM_HOST="$VMHost"
VM_PATH="$VMPath"

echo "Copiando arquivos para `${VM_USER}@`${VM_HOST}:`${VM_PATH}..."

scp asterisk_etc/extensions-modular.conf `${VM_USER}@`${VM_HOST}:`${VM_PATH}/asterisk_etc/
scp asterisk_etc/extensions-features.conf `${VM_USER}@`${VM_HOST}:`${VM_PATH}/asterisk_etc/
scp asterisk_etc/routing.conf `${VM_USER}@`${VM_HOST}:`${VM_PATH}/asterisk_etc/
scp asterisk_etc/tenants.conf `${VM_USER}@`${VM_HOST}:`${VM_PATH}/asterisk_etc/
scp scripts/ativar-dialplan-modular.sh `${VM_USER}@`${VM_HOST}:`${VM_PATH}/scripts/

echo "Cópia concluída!"
echo ""
echo "Agora execute na VM:"
echo "  ssh `${VM_USER}@`${VM_HOST}"
echo "  cd `${VM_PATH}"
echo "  chmod +x scripts/ativar-dialplan-modular.sh"
echo "  ./scripts/ativar-dialplan-modular.sh"
"@
    
    Set-Content -Path "copiar-scp.sh" -Value $scpScript
    Write-Host "  ✓ Script criado: copiar-scp.sh" -ForegroundColor Green
    Write-Host "  Execute: bash copiar-scp.sh (no WSL ou Git Bash)" -ForegroundColor Cyan
    Write-Host ""
}
