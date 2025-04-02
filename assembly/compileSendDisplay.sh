#!/bin/bash

# Verifica se o usuário passou o nome do arquivo como argumento
if [ -z "$1" ]; then
  echo "Uso: ./compila_envia.sh <arquivo_assembly_sem_extensao>"
  exit 1
fi

FILE="$1"  # Nome do arquivo passado como argumento

# Verifica se o arquivo existe
if [ ! -f "$FILE.asm" ]; then
  echo "Erro: Arquivo '$FILE.asm' não encontrado!"
  exit 1
fi

# Compilar o arquivo .asm para .hex
echo "Compilando $FILE.asm..."
avra "$FILE.asm"

# Verifica se a compilação gerou o arquivo .hex
if [ ! -f "$FILE.hex" ]; then
  echo "Erro: A compilação falhou!"
  exit 1
fi

# Listar portas disponíveis
echo "Procurando porta serial..."
PORT=$(ls /dev/ttyACM* 2>/dev/null | head -n 1)

# Se não encontrar, pedir ao usuário
if [ -z "$PORT" ]; then
  read -p "Digite a porta serial (ex: /dev/ttyACM0): " PORT
fi

# Enviar código para o ATmega2560
echo "Enviando $FILE.hex para $PORT..."
avrdude -c wiring -p m2560 -P "$PORT" -b 115200 -D -U flash:w:"$FILE.hex":i

echo "Processo concluído!"

screen /dev/ttyACM0 9600