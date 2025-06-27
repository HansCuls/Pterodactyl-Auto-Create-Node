#!/bin/bash

# Minta input dari pengguna.
echo "Masukkan nama lokasi: "
read location_name
echo "Masukkan deskripsi lokasi: "
read location_description
echo "Masukkan domain: "
read domain
echo "Masukkan nama node: "
read node_name
echo "Masukkan RAM (dalam MB): "
read ram
echo "Masukkan jumlah maksimum disk space (dalam MB): "
read disk_space
echo "Masukkan Locid: "
read locid
echo "Masukkan IP address untuk allocation: "
read ip_address
echo "Masukkan Port (contoh: 25565): "
read port
echo "Masukkan IP alias (boleh kosong): "
read ip_alias
echo "Masukkan domain node: "
read domain_node

# Ubah ke direktori pterodactyl
cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

# Membuat lokasi baru
php artisan p:location:make <<EOF
$location_name
$location_description
EOF

# Membuat node baru dan simpan output untuk mendapatkan node ID
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

# Ekstrak node ID dari output (asumsi output berisi ID)
# Catatan: Anda perlu menyesuaikan pola pencarian berdasarkan output sebenarnya
node_id=$(echo "$node_output" | grep -oP 'Node created with ID: \K\d+')
if [ -z "$node_id" ]; then
    echo "Gagal mendapatkan ID node. Silakan periksa manual."
    exit 1
fi

# Membuat alokasi
php artisan p:allocation:make <<EOF
$node_name
$ip_address
$port
$ip_alias
$domain_node
EOF

# Membuat token node secara otomatis
token_output=$(php artisan p:node:make-token --node="$node_id")
if [ $? -eq 0 ]; then
    echo "Token node berhasil dibuat:"
    echo "$token_output"
else
    echo "Gagal membuat token node."
    exit 1
fi

echo "Proses pembuatan node dan token telah selesai."
exit 0