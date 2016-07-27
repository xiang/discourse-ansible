install -o root -g root -m 0600 /dev/null /swapfile
dd if=/dev/zero of=/swapfile bs=1k count=2048k
mkswap /swapfile
swapon /swapfile
echo "/swapfile       swap    swap    auto      0       0" | tee -a /etc/fstab
sysctl -w vm.swappiness=10
echo vm.swappiness = 10 | tee -a /etc/sysctl.conf
