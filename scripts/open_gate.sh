#!/bin/bash
# ============================================
# Script para abrir portão via GPIO/HTTP/MQTT
# Chamado pelo Asterisk dialplan
# ============================================

GATE_NAME=$1

# Log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Abrindo portão: ${GATE_NAME}" >> /var/log/asterisk/gate_openings.log

# ============================================
# MÉTODO 1: GPIO (Raspberry Pi)
# ============================================
if command -v gpio &> /dev/null; then
    case ${GATE_NAME} in
        social)
            GPIO_PIN=17
            ;;
        garagem)
            GPIO_PIN=27
            ;;
        fundos)
            GPIO_PIN=22
            ;;
        *)
            echo "Portão desconhecido: ${GATE_NAME}"
            exit 1
            ;;
    esac
    
    echo "Ativando GPIO ${GPIO_PIN} por 3 segundos..."
    gpio mode ${GPIO_PIN} out
    gpio write ${GPIO_PIN} 1
    sleep 3
    gpio write ${GPIO_PIN} 0
    echo "Portão ${GATE_NAME} aberto via GPIO ${GPIO_PIN}"
    exit 0
fi

# ============================================
# MÉTODO 2: HTTP API (Controladora IP)
# ============================================
if command -v curl &> /dev/null; then
    case ${GATE_NAME} in
        social)
            API_URL="http://192.168.1.100/relay/1/on"
            ;;
        garagem)
            API_URL="http://192.168.1.100/relay/2/on"
            ;;
        fundos)
            API_URL="http://192.168.1.100/relay/3/on"
            ;;
        *)
            echo "Portão desconhecido: ${GATE_NAME}"
            exit 1
            ;;
    esac
    
    echo "Enviando comando HTTP para ${API_URL}..."
    curl -X POST "${API_URL}" -H "Content-Type: application/json" -d '{"duration":3}' --max-time 5
    
    if [ $? -eq 0 ]; then
        echo "Portão ${GATE_NAME} aberto via HTTP"
        exit 0
    else
        echo "Erro ao abrir portão ${GATE_NAME} via HTTP"
        exit 1
    fi
fi

# ============================================
# MÉTODO 3: MQTT (IoT)
# ============================================
if command -v mosquitto_pub &> /dev/null; then
    MQTT_BROKER="192.168.1.200"
    MQTT_TOPIC="portoes/${GATE_NAME}/comando"
    
    echo "Enviando comando MQTT para ${MQTT_BROKER}/${MQTT_TOPIC}..."
    mosquitto_pub -h ${MQTT_BROKER} -t ${MQTT_TOPIC} -m "OPEN" -q 1
    
    if [ $? -eq 0 ]; then
        echo "Portão ${GATE_NAME} aberto via MQTT"
        exit 0
    else
        echo "Erro ao abrir portão ${GATE_NAME} via MQTT"
        exit 1
    fi
fi

# ============================================
# MÉTODO 4: AMI Originate (Simular chamada para interfone)
# ============================================
if command -v asterisk &> /dev/null; then
    case ${GATE_NAME} in
        social)
            GATE_EXTENSION="8001"
            ;;
        garagem)
            GATE_EXTENSION="8002"
            ;;
        fundos)
            GATE_EXTENSION="8003"
            ;;
        *)
            echo "Portão desconhecido: ${GATE_NAME}"
            exit 1
            ;;
    esac
    
    echo "Originando chamada para extensão ${GATE_EXTENSION} (portão ${GATE_NAME})..."
    asterisk -rx "channel originate PJSIP/${GATE_EXTENSION} application Playback tt-monkeys"
    
    if [ $? -eq 0 ]; then
        echo "Portão ${GATE_NAME} aberto via AMI Originate"
        exit 0
    else
        echo "Erro ao abrir portão ${GATE_NAME} via AMI"
        exit 1
    fi
fi

# ============================================
# FALLBACK: Nenhum método disponível
# ============================================
echo "ERRO: Nenhum método de abertura de portão disponível (GPIO, HTTP, MQTT, AMI)"
exit 1
