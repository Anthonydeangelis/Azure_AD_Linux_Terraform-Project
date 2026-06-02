updatensglinux() {

  MYIP=$(curl -4 -s ifconfig.me)

  echo "Current IP: $MYIP"

  az network nsg rule update \
    --resource-group Anthony-Lab-RG \
    --nsg-name linux-subnet-nsg \
    --name allow-ssh \
    --source-address-prefixes "$MYIP/32"

  echo "NSG updated."
}

updatensgwindows() {

  MYIP=$(curl -4 -s ifconfig.me)

  echo "Current IP: $MYIP"

  az network nsg rule update \
    --resource-group Anthony-Lab-RG \
    --nsg-name windows-subnet-nsg \
    --name allow-ssh-windows \
    --source-address-prefixes "$MYIP/32"

  echo "NSG updated."
} 