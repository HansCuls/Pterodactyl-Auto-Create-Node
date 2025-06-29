#!/bin/bash

# Minta input dari pengguna
echo "Masukkan nama lokasi: "
read location_name
echo "Masukkan deskripsi lokasi: "
read location_description
echo "Masukkan domain panel (contoh: panel.public.enzoxavier.my.id): "
read domain
echo "Masukkan nama node: "
read node_name
echo "Masukkan RAM (dalam MB): "
read ram
echo "Masukkan jumlah maksimum disk space (dalam MB): "
read disk_space
echo "Masukkan LocID (angka lokasi): "
read locid
echo "Masukkan IP address untuk allocation: "
read ip_address
echo "Masukkan Port (contoh: 25565): "
read port
echo "Masukkan IP alias (boleh kosong): "
read ip_alias
echo "Masukkan domain node (contoh: node1.public.enzoxavier.my.id): "
read domain_node

# Pindah ke direktori panel
cd /var/www/pterodactyl || { echo "Direktori /var/www/pterodactyl tidak ditemukan"; exit 1; }

# Membuat lokasi baru
php artisan p:location:make <<EOF
$location_name
$location_description
EOF

# Membuat node dan menyimpan output
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

# Ambil Node ID dari output
node_id=$(echo "$node_output" | grep -oP 'Node created with ID:\s*\K\d+')

if [ -z "$node_id" ]; then
    echo "❌ Gagal mendapatkan ID node dari output:"
    echo "$node_output"
    exit 1
fi

echo "✅ Node berhasil dibuat dengan ID: $node_id"

# Membuat alokasi
php artisan p:allocation:make <<EOF
$node_name
$ip_address
$port
$ip_alias
$domain_node
EOF

# Membuat token node
token_output=$(php artisan p:node:make-token --node="$node_id")

if [ $? -eq 0 ]; then
    echo "✅ Token node berhasil dibuat."

    # Ambil token dari output
    token=$(echo "$token_output" | grep -oP 'ptla_\w+')

    if [ -n "$token" ]; then
        echo "🔐 Token: $token"
        echo ""
        echo "👉 Perintah untuk konfigurasi wings:"
        echo "cd /etc/pterodactyl && sudo wings configure --panel-url https://$domain --token $token --node $node_id"
    else
        echo "❌ Gagal mengambil token dari output:"
        echo "$token_output"
    fi
else
    echo "❌ Gagal membuat token node."
    exit 1
fi

echo "✅ Semua proses selesai."
exit 0
