#Config samaba file
sudo tee /etc/samba/smb.conf > /dev/null << 'EOF'
[global]
    workgroup = ANTSDOMAIN
    realm = ANTSDOMAIN.LOCAL
    server string = Linux File Server
    security = ADS
    kerberos method = secrets and keytab
    idmap config * : backend = tdb
    idmap config * : range = 10000-99999
    idmap config ANTSDOMAIN : backend = ad
    idmap config ANTSDOMAIN : range = 1433000000-1433999999
    template shell = /bin/bash
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file

[shared]
    comment = AD Authenticated Share
    path = /srv/samba/shared
    valid users = @"ANTSDOMAIN\DL-LinuxShare-RW"
    read only = no
    browseable = yes
    create mask = 0660
    directory mask = 0770
EOF

#Ensures the Samba configuration file is valid and there are no syntax errors. If there are any issues, it will provide details to help you troubleshoot.
testparm

sudo mkdir -p /srv/samba/shared
sudo chown root:"domain users@antsdomain.local" /srv/samba/shared
sudo chmod 2770 /srv/samba/shared
ls -la /srv/samba/shared

sudo systemctl restart smbd winbind
sudo systemctl status smbd

sudo ufw allow from 10.0.1.0/24 to any port 445
sudo ufw status

# Add SSH rule first before enabling or you'll lock yourself out
sudo ufw allow from YOUR.HOME.IP to any port 22
sudo ufw allow from 10.0.1.0/24 to any port 445
sudo ufw enable
sudo ufw status verbose

