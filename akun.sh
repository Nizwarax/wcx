#!/bin/bash

# Warna
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

ACCOUNTS_FILE="accounts.json"
OLD_ACCOUNT_FILE="akun.txt"

# ... (sisa fungsi akan mengikuti)
# Fungsi untuk menampilkan header
display_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${GREEN}      👤  K E L O L A   A K U N   C F           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
}

# Fungsi untuk memastikan jq terinstal
ensure_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Perintah 'jq' tidak ditemukan. Ini diperlukan untuk mengelola file akun JSON.${NC}"
        echo -e "${YELLOW}Mencoba menginstal jq...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        else
            echo -e "${RED}Tidak dapat menginstal jq secara otomatis. Harap instal secara manual.${NC}"
            exit 1
        fi
    fi
}

# Fungsi untuk memigrasikan akun.txt ke accounts.json
migrate_old_account_file() {
    if [ -f "$OLD_ACCOUNT_FILE" ] && [ ! -f "$ACCOUNTS_FILE" ]; then
        echo -e "${YELLOW}File akun.txt lama terdeteksi. Memigrasikan ke format baru...${NC}"
        echo "[]" > "$ACCOUNTS_FILE"
        source "$OLD_ACCOUNT_FILE"
        echo -e "${YELLOW}Harap berikan nama panggilan untuk akun yang diimpor ini (misalnya: Akun Utama):${NC}"
        read -r account_name
        if [ -z "$account_name" ]; then
            account_name="Akun Terimpor"
        fi
        new_account=$(jq -n \
            --arg name "$account_name" \
            --arg email "$AUTH_EMAIL" \
            --arg key "$AUTH_KEY" \
            --arg id "$ACCOUNT_ID" \
            --arg zone "$ZONE_ID" \
            '{name: $name, email: $email, api_key: $key, account_id: $id, zone_id: $zone}')
        jq --argjson new_account "$new_account" '. += [$new_account]' "$ACCOUNTS_FILE" > tmp.$$.json && mv tmp.$$.json "$ACCOUNTS_FILE"
        echo -e "${GREEN}Migrasi berhasil!${NC}"
        mv "$OLD_ACCOUNT_FILE" "${OLD_ACCOUNT_FILE}.migrated"
        echo -e "${YELLOW}File akun.txt lama telah diganti nama menjadi ${OLD_ACCOUNT_FILE}.migrated${NC}"
        sleep 2
    fi
}

# Fungsi untuk menambah akun baru
add_account() {
    display_header
    echo -e "${YELLOW}Masukkan nama panggilan untuk akun baru ini (misalnya: Akun Kerja):${NC}"
    read -r name
    echo -e "${YELLOW}Masukkan Email Cloudflare:${NC}"
    read -r email
    echo -e "${YELLOW}Masukkan Kunci API Global Cloudflare:${NC}"
    read -r api_key
    echo -e "${YELLOW}Masukkan ID Akun Cloudflare:${NC}"
    read -r account_id
    echo -e "${YELLOW}Masukkan ID Zona Cloudflare:${NC}"
    read -r zone_id

    new_account=$(jq -n \
        --arg name "$name" \
        --arg email "$email" \
        --arg key "$api_key" \
        --arg id "$account_id" \
        --arg zone "$zone_id" \
        '{name: $name, email: $email, api_key: $key, account_id: $id, zone_id: $zone}')

    jq --argjson new_account "$new_account" '. += [$new_account]' "$ACCOUNTS_FILE" > tmp.$$.json && mv tmp.$$.json "$ACCOUNTS_FILE"
    echo -e "${GREEN}Akun '$name' berhasil ditambahkan!${NC}"
    sleep 1
}

# Fungsi untuk menampilkan daftar akun
list_accounts() {
    display_header
    echo -e "${CYAN}Daftar Akun Cloudflare Tersimpan:${NC}"
    jq -r '.[] | .name' "$ACCOUNTS_FILE" | cat -n
    echo -e "\n${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read -r
}

# Fungsi untuk mengedit akun
edit_account() {
    display_header
    echo -e "${CYAN}Pilih akun yang ingin Anda edit:${NC}"
    jq -r '.[] | .name' "$ACCOUNTS_FILE" | cat -n
    read -p "Masukkan nomor akun: " account_num

    account_index=$((account_num - 1))

    # Dapatkan detail akun saat ini
    current_name=$(jq -r ".[$account_index].name" "$ACCOUNTS_FILE")
    current_email=$(jq -r ".[$account_index].email" "$ACCOUNTS_FILE")
    current_api_key=$(jq -r ".[$account_index].api_key" "$ACCOUNTS_FILE")
    current_account_id=$(jq -r ".[$account_index].account_id" "$ACCOUNTS_FILE")
    current_zone_id=$(jq -r ".[$account_index].zone_id" "$ACCOUNTS_FILE")

    # Minta input baru
    echo -e "${YELLOW}Masukkan nama panggilan baru (saat ini: $current_name):${NC}"
    read -r name
    [ -z "$name" ] && name=$current_name

    echo -e "${YELLOW}Masukkan Email Cloudflare baru (saat ini: $current_email):${NC}"
    read -r email
    [ -z "$email" ] && email=$current_email

    echo -e "${YELLOW}Masukkan Kunci API Global baru (saat ini: $current_api_key):${NC}"
    read -r api_key
    [ -z "$api_key" ] && api_key=$current_api_key

    echo -e "${YELLOW}Masukkan ID Akun baru (saat ini: $current_account_id):${NC}"
    read -r account_id
    [ -z "$account_id" ] && account_id=$current_account_id

    echo -e "${YELLOW}Masukkan ID Zona baru (saat ini: $current_zone_id):${NC}"
    read -r zone_id
    [ -z "$zone_id" ] && zone_id=$current_zone_id

    # Perbarui akun dalam file JSON
    jq --arg name "$name" \
       --arg email "$email" \
       --arg key "$api_key" \
       --arg id "$account_id" \
       --arg zone "$zone_id" \
       ".[${account_index}] = {name: \$name, email: \$email, api_key: \$key, account_id: \$id, zone_id: \$zone}" \
       "$ACCOUNTS_FILE" > tmp.$$.json && mv tmp.$$.json "$ACCOUNTS_FILE"

    echo -e "${GREEN}Akun berhasil diperbarui!${NC}"
    sleep 1
}

# Fungsi untuk menghapus akun
delete_account() {
    display_header
    echo -e "${CYAN}Pilih akun yang ingin Anda hapus:${NC}"
    jq -r '.[] | .name' "$ACCOUNTS_FILE" | cat -n
    read -p "Masukkan nomor akun: " account_num

    account_index=$((account_num - 1))

    # Hapus akun dari file JSON
    jq "del(.[$account_index])" "$ACCOUNTS_FILE" > tmp.$$.json && mv tmp.$$.json "$ACCOUNTS_FILE"

    echo -e "${GREEN}Akun berhasil dihapus!${NC}"
    sleep 1
}

# Menu Utama
main_menu() {
    while true; do
        display_header
        echo -e "\n${CYAN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}${GREEN}     M E N U   K E L O L A   A K U N            ${NC}${CYAN}║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}1. ➕ Tambah Akun Baru${NC}                         ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}2. 📄 Tampilkan Daftar Akun${NC}                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}3. ✏️ Edit Akun${NC}                               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}4. 🗑️ Hapus Akun${NC}                              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}0. 🚪 Kembali ke Menu Utama${NC}                   ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"

        echo -e "\n${CYAN}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬${NC}"
        read -p " Pilih opsi [1-4/0]: " choice

        case $choice in
            1) add_account ;;
            2) list_accounts ;;
            3) edit_account ;;
            4) delete_account ;;
            0) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" && sleep 1 ;;
        esac
    done
}

# Inisialisasi
ensure_jq
migrate_old_account_file
if [ ! -f "$ACCOUNTS_FILE" ]; then
    echo "[]" > "$ACCOUNTS_FILE"
fi

# Jalankan menu utama
main_menu
