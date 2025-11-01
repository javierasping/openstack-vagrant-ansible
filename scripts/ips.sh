#!/bin/bash
# Script: actualizar_user_variables.sh
# Descripción: sincroniza contenedores LXC con user_variables.yml para OpenStack-Ansible

USER_VARS_FILE="$HOME/openstack-vagrant-ansible/user_variables.yml"
SSH_KEY="$HOME/openstack-vagrant-ansible/keys/id_rsa"

declare -A LXC_HOSTS=(
  ["172.16.0.11"]="controller01"
  ["172.16.0.12"]="network01"
  ["172.16.0.13"]="compute01"
  ["172.16.0.14"]="storage01"
)

echo "Actualizando $USER_VARS_FILE..."

for HOST in "${!LXC_HOSTS[@]}"; do
    PREFIX="${LXC_HOSTS[$HOST]}"
    echo "Conectando a $HOST..."

    # Comprobar si lxc-ls existe
    ssh -i $SSH_KEY -o StrictHostKeyChecking=no root@$HOST "command -v lxc-ls" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "lxc-ls no encontrado en $HOST, saltando..."
        continue
    fi

    # Extraer contenedores y su primera IP
    ssh -i $SSH_KEY -o StrictHostKeyChecking=no root@$HOST \
        "lxc-ls -f | tail -n +2 | awk '{split(\$5,a,\",\"); print \$1,a[1]}'" \
    | while read CONTAINER IP; do
        # Saltar contenedores sin IP
        [ "$IP" == "-" ] && continue
        VAR_NAME=$(echo $CONTAINER | sed 's/-/_/g')

        # Revisar si ya existe en user_variables.yml
        grep -q "$VAR_NAME:" "$USER_VARS_FILE"
        if [ $? -eq 0 ]; then
            # Actualizar IP existente
            echo "Actualizando $VAR_NAME con IP $IP..."
            sed -i "/$VAR_NAME:/,/ip:/ s/ip: .*/ip: $IP/" "$USER_VARS_FILE"
        else
            # Crear bloque YAML nuevo
            echo "Agregando $VAR_NAME con IP $IP..."
            cat <<EOL >> "$USER_VARS_FILE"
${VAR_NAME}:
  ip: $IP
EOL
        fi
    done
done

echo "Actualización completa."
