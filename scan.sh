#!/bin/bash
clear

# Define color codes
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
purple='\e[1;34m'
cyan='\e[1;36m'
white='\e[1;37m'
reset='\e[0m'

# Security notice
show_security_notice() {
    clear
    echo -e "${red}╔════════════════════════════════════════════════════════╗${reset}"
    echo -e "${red}║           ⚠️  SECURITY NOTICE  ⚠️                      ║${reset}"
    echo -e "${red}╚════════════════════════════════════════════════════════╝${reset}"
    echo ""
    echo -e "${yellow}This script will download and execute code from external sources.${reset}"
    echo -e "${yellow}Only safe IP scanning features are included in this version.${reset}"
    echo ""
    echo -e "${cyan}Features removed for security:${reset}"
    echo -e "  ${red}✗${reset} License Cloner (illegal/ToS violation)"
    echo -e "  ${red}✗${reset} Config generators (untrusted sources)"
    echo -e "  ${red}✗${reset} Third-party installers"
    echo ""
    echo -e "${green}Included safe features:${reset}"
    echo -e "  ${green}✓${reset} IPv4 WARP Scanner"
    echo -e "  ${green}✓${reset} Fastly CDN Scanner"
    echo -e "  ${green}✓${reset} Gcore Scanner"
    echo ""
    echo -e "${purple}═══════════════════════════════════════════════════════${reset}"
    echo -en "${cyan}Press Enter to continue or Ctrl+C to exit: ${reset}"
    read
}

# Show security notice once at start
show_security_notice

clear
if command -v figlet &>/dev/null; then
    figlet -f slant "IP SCANNER"
fi
echo -e "${cyan}*****************************************${reset}"
echo -e "${cyan}*${reset} ${red}S${green}E${yellow}C${purple}U${cyan}R${green}E${reset} ${white}I${red}P${reset} ${green}S${yellow}C${purple}A${cyan}N${green}N${white}E${red}R${reset}         ${cyan}"
echo -e "${cyan}*${reset} ${green}Safe IP scanning tools${reset}              ${cyan}"
echo -e "${cyan}*${reset} ${purple}Based on KOLAND scripts${reset}            ${cyan}"
echo -e "${cyan}*****************************************${reset}"
echo -e "${cyan}* ${green}Date:${reset} $(date '+%Y-%m-%d %H:%M:%S') ${cyan}*${reset}"
echo ""

echo -e "${cyan}+----+---------------------------------------------+${reset}"
echo -e "${green}| No | Option                                      |${reset}"
echo -e "${cyan}+----+---------------------------------------------+${reset}"
printf "${cyan}| ${yellow}%-2s ${cyan}| ${yellow}%-43s ${cyan}|\n" "1" "IPv4 WARP Endpoint Scanner"
printf "${cyan}| ${yellow}%-2s ${cyan}| ${yellow}%-43s ${cyan}|\n" "2" "Fastly CDN IP Scanner"
printf "${cyan}| ${yellow}%-2s ${cyan}| ${yellow}%-43s ${cyan}|\n" "3" "Gcore IP Scanner"
printf "${cyan}| ${yellow}%-2s ${cyan}| ${yellow}%-43s ${cyan}|\n" "0" "Exit"
echo -e "${cyan}+----+---------------------------------------------+${reset}"
echo ""
echo -e "${purple}📌 Note: All scanners find IPs with lowest latency${reset}"
echo ""
echo -en "${green}Enter your choice: ${reset}"
read -r user_input

# Function to measure IPv4 latency
measure_latency() {
    local ip_port=$1
    local ip=$(echo $ip_port | cut -d: -f1)
    local latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
    if [ -z "$latency" ]; then
        latency="N/A"
    fi
    printf "| %-21s | %-10s |\n" "$ip_port" "$latency"
}

# Function to display IPv4 table
display_table_ipv4() {
    printf "+-----------------------+------------+\n"
    printf "| IP:Port               | Latency(ms) |\n"
    printf "+-----------------------+------------+\n"
    echo "$1" | head -n 10 | while read -r ip_port; do 
        measure_latency "$ip_port"
    done
    printf "+-----------------------+------------+\n"
}

# Function to confirm external script execution
confirm_execution() {
    local script_name=$1
    echo ""
    echo -e "${yellow}⚠️  About to download and execute: ${script_name}${reset}"
    echo -e "${cyan}Source: GitHub (external)${reset}"
    echo -e "${red}Risk: Script content could change at any time${reset}"
    echo ""
    echo -en "${green}Continue? (yes/no): ${reset}"
    read -r confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${red}Cancelled by user.${reset}"
        exit 0
    fi
}

# Option 1: IPv4 WARP Scanner
if [ "$user_input" -eq 1 ]; then
    clear
    echo -e "${purple}═══════════════════════════════════════${reset}"
    echo -e "${cyan}  IPv4 WARP Endpoint Scanner${reset}"
    echo -e "${purple}═══════════════════════════════════════${reset}"
    
    confirm_execution "IPv4 Scanner from Ptechgithub"
    
    echo -e "${green}Fetching IPv4 addresses...${reset}"
    echo ""
    
    # Execute the scanner
    ip_list=$(echo "1" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}:\d+')
    
    if [ -z "$ip_list" ]; then
        echo -e "${red}Error: Failed to fetch IP addresses${reset}"
        echo -e "${yellow}Possible reasons:${reset}"
        echo -e "  - Network connection issue"
        echo -e "  - Source script unavailable"
        echo -e "  - Firewall blocking the request"
        exit 1
    fi
    
    clear
    echo -e "${purple}═══════════════════════════════════════${reset}"
    echo -e "${green}  Top 10 IPv4 WARP Endpoints${reset}"
    echo -e "${purple}═══════════════════════════════════════${reset}"
    echo ""
    display_table_ipv4 "$ip_list"
    echo ""
    echo -e "${cyan}💡 Tip: Use the IP with lowest latency in your WARP config${reset}"
    
# Option 2: Fastly CDN Scanner
elif [ "$user_input" -eq 2 ]; then
    clear
    echo -e "${purple}═══════════════════════════════════════${reset}"
    echo -e "${cyan}  Fastly CDN IP Scanner${reset}"
    echo -e "${purple}═══════════════════════════════════════${reset}"
    
    confirm_execution "Fastly Scanner from Kolandone"
    
    echo -e "${green}Scanning Fastly CDN IPs...${reset}"
    echo -e "${yellow}This may take a few minutes...${reset}"
    echo ""
    
    # Execute the scanner
    bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/fastlyipscan/refs/heads/main/ipscan.sh) 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${red}Error: Failed to run Fastly scanner${reset}"
        echo -e "${yellow}Please check your internet connection and try again${reset}"
        exit 1
    fi

# Option 3: Gcore Scanner
elif [ "$user_input" -eq 3 ]; then
    clear
    echo -e "${purple}═══════════════════════════════════════${reset}"
    echo -e "${cyan}  Gcore IP Scanner${reset}"
    echo -e "${purple}═══════════════════════════════════════${reset}"
    
    confirm_execution "Gcore Scanner from Kolandone"
    
    echo -e "${green}Scanning Gcore IPs...${reset}"
    echo -e "${yellow}This may take a few minutes...${reset}"
    echo ""
    
    # Execute the scanner
    bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/gcorescanner/refs/heads/main/gcore.sh) 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${red}Error: Failed to run Gcore scanner${reset}"
        echo -e "${yellow}Please check your internet connection and try again${reset}"
        exit 1
    fi

# Option 0: Exit
elif [ "$user_input" -eq 0 ]; then
    echo ""
    echo -e "${cyan}Goodbye! Stay safe! 👋${reset}"
    exit 0

# Invalid input
else 
    echo ""
    echo -e "${red}Invalid input. Please enter 1, 2, 3, or 0${reset}"
    exit 1
fi

# End message
echo ""
echo -e "${green}═══════════════════════════════════════${reset}"
echo -e "${cyan}  Scan completed successfully! ✓${reset}"
echo -e "${green}═══════════════════════════════════════${reset}"
echo ""
echo -e "${yellow}📋 Next steps:${reset}"
echo -e "  1. Copy the IP with lowest latency"
echo -e "  2. Use it in your VPN/proxy configuration"
echo -e "  3. Test the connection"
echo ""
echo -e "${purple}⚠️  Security reminder:${reset}"
echo -e "  • These are public IPs, not private tunnels"
echo -e "  • Always use with proper VPN/encryption"
echo -e "  • IPs may change or become unavailable"
echo ""
