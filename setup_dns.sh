#!/bin/bash

# Function to install DNS essential services
install_dns() {
    echo "Installing BIND DNS server..."
    sudo dnf install -y bind bind-utils
    sudo systemctl enable named
}

# Function to create the zone file
create_zone_file() {
    local domain_name="$1"
    local ip_address="$2"
    local db_file="/var/named/${domain_name}.db"

    # Create zone file
    echo "\$TTL    604800  ; Default TTL for the zone" | sudo tee "$db_file"
    echo "\$ORIGIN $domain_name." | sudo tee -a "$db_file"
    echo "@       IN      SOA     ns.$domain_name. admin.$domain_name. (" | sudo tee -a "$db_file"
    echo "                           1         ; Serial" | sudo tee -a "$db_file"
    echo "                       604800         ; Refresh" | sudo tee -a "$db_file"
    echo "                        86400         ; Retry" | sudo tee -a "$db_file"
    echo "                      2419200         ; Expire" | sudo tee -a "$db_file"
    echo "                       604800 )       ; Negative Cache TTL" | sudo tee -a "$db_file"
    echo "" | sudo tee -a "$db_file"
    echo "@       IN      NS      ns.$domain_name." | sudo tee -a "$db_file"
    echo "ns      IN      A       $ip_address  ; DNS server IP" | sudo tee -a "$db_file"
    echo "@       IN      A       $ip_address  ; Domain IP" | sudo tee -a "$db_file"
}

# Function to configure named.conf
configure_named() {
    local domain_name="$1"
    local named_conf="/etc/named.conf"

    # Add zone configuration to named.conf
    echo "zone \"$domain_name\" IN {" | sudo tee -a "$named_conf"
    echo "    type master;" | sudo tee -a "$named_conf"
    echo "    file \"/var/named/${domain_name}.db\";" | sudo tee -a "$named_conf"
    echo "};" | sudo tee -a "$named_conf"
}

# Function to check and restart the named service
restart_named() {
    sudo named-checkzone "$1" "/var/named/$1.db"
    if [[ $? -eq 0 ]]; then
        echo "Zone file for $1 is OK. Restarting named service..."
        sudo systemctl restart named
    else
        echo "Zone file for $1 has errors. Please check."
        exit 1
    fi
}

# Main script execution
read -p "Enter the domain name (e.g., example.com): " domain_name
read -p "Enter the DNS server IP address (e.g., 192.168.1.1): " ip_address

install_dns
create_zone_file "$domain_name" "$ip_address"
configure_named "$domain_name"
restart_named "$domain_name"

echo "DNS setup complete for $domain_name with IP $ip_address."
