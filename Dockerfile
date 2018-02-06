FROM debian:stretch

sed -n '/```shell/,/```/p; 1d' Mail-server_Package-installation.md | sed '$d; 1d'

