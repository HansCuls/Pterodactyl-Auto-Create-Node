#!/bin/bash

# Minta input dari pengguna
read -p "Nama lokasi: " location_name
read -p "Deskripsi lokasi: " location_description
read -p "Domain: " domain
read -p "Nama node: " node_name
read -p "RAM (MB): " ram
read -p "Disk Space (MB): " disk_space
read -p "LocID: " locid
read -p "IP Address: " ip_address
read -p "Port (cth: 25565): " port
read -p "IP Alias (boleh kosong): " ip_alias
read -p "Domain Node: " domain_node

# Ubah direktori ke folder Pterodactyl
cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

# Buat lokasi
php artisan p:location:make <<EOF
$location_name
$location_description
EOF

# Buat node
node_output=$(php artisan p:node:make <<EOF
$node_name
$location_description
$locid
https
$domain
yes
no
no
$ram
$ram
$disk_space
$disk_space
100
8080
2022
/var/lib/pterodactyl/volumes
EOF
)

# Tangkap Node ID dari output
node_id=$(echo "$node_output" | grep -oP 'ID:\s*\K\d+')

if [ -z "$node_id" ]; then
    echo "Gagal mendapatkan Node ID. Output:"
    echo "$node_output"
    exit 1
fi

# Buat alokasi
php artisan p:allocation:make <<EOF
$node_name
$ip_address
$port
$ip_alias
$domain_node
EOF

# Buat token
token_output=$(php artisan p:node:make-token --node="$node_id")

if [ $? -eq 0 ]; then
    echo "✅ Token berhasil dibuat:"
    echo "$token_output"
else
    echo "❌ Gagal membuat token node."
    exit 1
fi

echo "🎉 Node dan token selesai dibuat!"
exit 0
