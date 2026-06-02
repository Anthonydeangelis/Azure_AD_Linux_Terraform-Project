#Config samaba file
[global]
    workgroup = ANTSDOMAIN
    realm = ANTSDOMAIN.LOCAL
    server string = Linux File Server
    security = ADS
    
    # Winbind
    idmap config * : backend = tdb
    idmap config * : range = 10000-99999
    idmap config ANTSDOMAIN : backend = ad
    idmap config ANTSDOMAIN : range = 1433000000-1433999999
    winbind use default domain = yes
    winbind offline logon = false
    template shell = /bin/bash

    # Logging
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file


    [shared]
    comment = AD Authenticated Share
    path = /srv/samba/shared

    #This tells us what users/groups have access to the share. In this case, we are allowing members of the DL-LinuxShare-RW group in the ANTSDOMAIN to have read/write access to the share.
    valid users = @"ANTSDOMAIN\DL-LinuxShare-RW"
    read only = no
    browseable = yes
    create mask = 0660
    directory mask = 0770

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

