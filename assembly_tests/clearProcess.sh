#!/bin/bash

PORT="/dev/ttyACM0"

# Verifica se há processos usando a porta
PIDS=$(fuser "$PORT" 2>/dev/null)

if [ -z "$PIDS" ]; then
  echo "Nenhum processo está usando $PORT."
else
  echo "Matando processos que estão usando $PORT..."
  sudo kill -9 $PIDS
  echo "Processos eliminados!"
fi
