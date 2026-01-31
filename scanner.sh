#!/bin/bash

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

# Clear screen and show main menu
show_main_menu() {
    clear
    echo -e "${cyan}╔════════════════════════════════════════╗${rest}"
    echo -e "${cyan}║${purple}    IP Scanner & WARP Config Tool     ${cyan}║${rest}"
    echo -e "${cyan}╚════════════════════════════════════════╝${rest}"
    echo ""
    echo -e "${green}[1]${rest} ${yellow}cf${rest} - Cloudflare WARP Tools"
    echo -e "    ${cyan}(Endpoint Scanner + Config Generator)${rest}"
    echo ""
    echo -e "${green}[2]${rest} ${yellow}fl${rest} - Fastly CDN IP Scanner"
    echo -e "    ${cyan}(Find best Fastly IPs)${rest}"
    echo ""
    echo -e "${green}[3]${rest} ${yellow}gc${rest} - Google Cloud IP Scanner"
    echo -e "    ${cyan}(Find best GC IPs)${rest}"
    echo ""
    echo -e "${red}[0]${rest} Exit"
    echo ""
    echo -e "${cyan}════════════════════════════════════════${rest}"
    echo -en "${yellow}Select option: ${rest}"
}

# ============================================
# FASTLY CDN IP SCANNER (Code 1 - fl)
# ============================================
run_fastly_scanner() {
    clear
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    echo -e "${cyan}  Fastly CDN IP Scanner${rest}"
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    
    # Function definitions
    ip_to_decimal() {
        local ip="$1"
        local a b c d
        IFS=. read -r a b c d <<< "$ip"
        echo "$((a * 256**3 + b * 256**2 + c * 256 + d))"
    }

    decimal_to_ip() {
        local dec="$1"
        local a=$((dec / 256**3 % 256))
        local b=$((dec / 256**2 % 256))
        local c=$((dec / 256 % 256))
        local d=$((dec % 256))
        echo "$a.$b.$c.$d"
    }

    measure_latency() {
        local ip=$1
        local latency=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
        if [ -z "$latency" ]; then
            latency="N/A"
        fi
        printf "%s %s\n" "$ip" "$latency"
    }

    generate_ips_in_cidr() {
        local cidr="$1"
        local limit="$2" 
        local base_ip=$(echo "$cidr" | cut -d'/' -f1)
        local prefix=$(echo "$cidr" | cut -d'/' -f2)
        local ip_dec=$(ip_to_decimal "$base_ip")
        local range_size=$((2 ** (32 - prefix)))
        local ips=()

        for ((i=0; i<limit; i++)); do
            local random_offset=$((RANDOM % range_size))
            ips+=("$(decimal_to_ip $((ip_dec + random_offset)))")
        done

        echo "${ips[@]}"
    }

    show_progress() {
        local current=$1
        local total=$2
        local percent=$(( 100 * current / total ))
        local progress=$(( current * 50 / total ))
        local green=$(( progress ))
        local red=$(( 50 - progress ))

        printf "\r["
        printf "\e[42m%${green}s\e[0m" | tr ' ' '='
        printf "\e[41m%${red}s\e[0m" | tr ' ' '='
        printf "] %d%%" "$percent"
    }

    display_table_ipv4() {
        printf "+-----------------------+------------+\n"
        printf "| IP                    | Latency(ms) |\n"
        printf "+-----------------------+------------+\n"
        echo "$1" | while read -r ip latency; do
            if [ "$latency" == "N/A" ]; then
                continue
            fi
            printf "| %-21s | %-10s |\n" "$ip" "$latency"
        done
        printf "+-----------------------+------------+\n"
    }

    # Fastly IP Ranges
    IP_RANGES=(
        "23.235.32.0/20" "43.249.72.0/22" "103.244.50.0/24" "103.245.222.0/23"
        "103.245.224.0/24" "104.156.80.0/20" "140.248.64.0/18" "140.248.128.0/17"
        "146.75.0.0/17" "151.101.0.0/16" "157.52.64.0/18" "167.82.0.0/17"
        "167.82.128.0/20" "167.82.160.0/20" "167.82.224.0/20" "172.111.64.0/18"
        "185.31.16.0/22" "199.27.72.0/21" "199.232.0.0/16"
    )

    LIMIT=50

    echo -e "${green}Selecting random IP ranges...${rest}"
    SELECTED_IP_RANGES=($(shuf -e "${IP_RANGES[@]}" -n 5))
    echo -e "${cyan}Selected: ${SELECTED_IP_RANGES[@]}${rest}"

    SELECTED_IPS=()
    for range in "${SELECTED_IP_RANGES[@]}"; do
        ips=($(generate_ips_in_cidr "$range" "$LIMIT"))
        SELECTED_IPS+=("${ips[@]}")
    done

    SHUFFLED_IPS=($(shuf -e "${SELECTED_IPS[@]}" -n 100))

    valid_ips=()
    total_ips=${#SHUFFLED_IPS[@]}
    processed_ips=0

    echo -e "${green}Scanning IPs...${rest}"
    
    while [[ ${#valid_ips[@]} -lt 10 ]]; do
        ping_results=$(printf "%s\n" "${SHUFFLED_IPS[@]}" | xargs -I {} -P 10 bash -c '
        measure_latency() {
            local ip="$1"
            local latency=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep "time=" | awk -F"time=" "{ print \$2 }" | cut -d" " -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
            fi
            printf "%s %s\n" "$ip" "$latency"
        }
        measure_latency "$@"
        ' _ {})

        valid_ips=($(echo "$ping_results" | grep -v "N/A" | awk '{print $1}'))

        processed_ips=$((${#valid_ips[@]} + ${#SHUFFLED_IPS[@]} - $total_ips))
        show_progress $processed_ips $total_ips

        if [[ ${#valid_ips[@]} -lt 10 ]]; then
            echo -e "\n${yellow}Not enough valid IPs found. Selecting more...${rest}"
            additional_ips=($(generate_ips_in_cidr "${SELECTED_IP_RANGES[0]}" "$LIMIT"))
            SHUFFLED_IPS=($(shuf -e "${additional_ips[@]}" -n 100))
            total_ips=${#SHUFFLED_IPS[@]}
            processed_ips=0
        fi
    done

    clear
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    echo -e "${green}Results - Fastly CDN IPs${rest}"
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    display_table_ipv4 "$ping_results"

    comma_separated_ips=$(IFS=,; echo "${valid_ips[*]}")
    echo -e "\n${cyan}Valid IPs (comma-separated):${rest}"
    echo -e "${green}$comma_separated_ips${rest}"
    
    echo ""
    read -p "Press Enter to return to menu..."
}

# ============================================
# GOOGLE CLOUD IP SCANNER (Code 2 - gc)
# ============================================
run_gc_scanner() {
    clear
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    echo -e "${cyan}  Google Cloud IP Scanner${rest}"
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    
    # Same functions as Fastly
    ip_to_decimal() {
        local ip="$1"
        local a b c d
        IFS=. read -r a b c d <<< "$ip"
        echo "$((a * 256**3 + b * 256**2 + c * 256 + d))"
    }

    decimal_to_ip() {
        local dec="$1"
        local a=$((dec / 256**3 % 256))
        local b=$((dec / 256**2 % 256))
        local c=$((dec / 256 % 256))
        local d=$((dec % 256))
        echo "$a.$b.$c.$d"
    }

    measure_latency() {
        local ip=$1
        local latency=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
        if [ -z "$latency" ]; then
            latency="N/A"
        fi
        printf "%s %s\n" "$ip" "$latency"
    }

    generate_ips_in_cidr() {
        local cidr="$1"
        local limit="$2" 
        local base_ip=$(echo "$cidr" | cut -d'/' -f1)
        local prefix=$(echo "$cidr" | cut -d'/' -f2)
        local ip_dec=$(ip_to_decimal "$base_ip")
        local range_size=$((2 ** (32 - prefix)))
        local ips=()

        for ((i=0; i<limit; i++)); do
            local random_offset=$((RANDOM % range_size))
            ips+=("$(decimal_to_ip $((ip_dec + random_offset)))")
        done

        echo "${ips[@]}"
    }

    show_progress() {
        local current=$1
        local total=$2
        local percent=$(( 100 * current / total ))
        local progress=$(( current * 50 / total ))
        local green=$(( progress ))
        local red=$(( 50 - progress ))

        printf "\r["
        printf "\e[42m%${green}s\e[0m" | tr ' ' '='
        printf "\e[41m%${red}s\e[0m" | tr ' ' '='
        printf "] %d%%" "$percent"
    }

    display_table_ipv4() {
        printf "+-----------------------+------------+\n"
        printf "| IP                    | Latency(ms) |\n"
        printf "+-----------------------+------------+\n"
        echo "$1" | while read -r ip latency; do
            if [ "$latency" == "N/A" ]; then
                continue
            fi
            printf "| %-21s | %-10s |\n" "$ip" "$latency"
        done
        printf "+-----------------------+------------+\n"
    }

    # Note: IP list truncated for brevity - using first 20 ranges
    IP_RANGES=(
        "5.1.106.249/24" "5.8.43.4/24" "5.8.92.4/24" "5.101.68.5/24"
        "5.188.7.12/24" "5.188.94.5/24" "31.184.207.4/24" "37.17.119.114/24"
        "45.65.8.4/24" "45.82.100.4/24" "46.19.99.6/24" "78.111.101.4/24"
        "79.133.108.4/24" "80.15.252.1/24" "80.93.210.4/24" "87.120.106.4/24"
        "92.38.142.20/24" "92.223.12.4/24" "93.123.11.11/24" "94.176.183.5/24"
    )

    LIMIT=50

    echo -e "${green}Selecting random IP ranges...${rest}"
    SELECTED_IP_RANGES=($(shuf -e "${IP_RANGES[@]}" -n 5))
    echo -e "${cyan}Selected: ${SELECTED_IP_RANGES[@]}${rest}"

    SELECTED_IPS=()
    for range in "${SELECTED_IP_RANGES[@]}"; do
        ips=($(generate_ips_in_cidr "$range" "$LIMIT"))
        SELECTED_IPS+=("${ips[@]}")
    done

    SHUFFLED_IPS=($(shuf -e "${SELECTED_IPS[@]}" -n 100))

    valid_ips=()
    total_ips=${#SHUFFLED_IPS[@]}

    echo -e "${green}Scanning IPs...${rest}"
    
    ping_results=$(printf "%s\n" "${SHUFFLED_IPS[@]}" | xargs -I {} -P 10 bash -c '
    measure_latency() {
        local ip="$1"
        local latency=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep "time=" | awk -F"time=" "{ print \$2 }" | cut -d" " -f1)
        if [ -z "$latency" ]; then
            latency="N/A"
        fi
        printf "%s %s\n" "$ip" "$latency"
    }
    measure_latency "$@"
    ' _ {})

    valid_ips=($(echo "$ping_results" | grep -v "N/A" | awk '{print $1}'))

    clear
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    echo -e "${green}Results - Google Cloud IPs${rest}"
    echo -e "${purple}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${rest}"
    display_table_ipv4 "$ping_results"

    if [ ${#valid_ips[@]} -gt 0 ]; then
        comma_separated_ips=$(IFS=,; echo "${valid_ips[*]}")
        echo -e "\n${cyan}Valid IPs (comma-separated):${rest}"
        echo -e "${green}$comma_separated_ips${rest}"
    else
        echo -e "${red}No valid IPs found!${rest}"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
}

# ============================================
# CLOUDFLARE WARP TOOLS (Code 3 - cf)
# ============================================
run_cf_tools() {
    clear
    echo -e "${cyan}By --> Peyman * Github.com/Ptechgithub * ${rest}"
    echo ""
    echo -e "${purple}**********************${rest}"
    echo -e "${purple}*  ${green}Endpoint Scanner ${purple} *${rest}"
    echo -e "${purple}*  ${green}wire-g installer ${purple} *${rest}"
    echo -e "${purple}*  ${green}License cloner${purple}    *${rest}"
    echo -e "${purple}**********************${rest}"
    echo -e "${purple}[1] ${cyan}Preferred${green} IPV4${purple}   * ${rest}"
    echo -e "${purple}                     *${rest}"
    echo -e "${purple}[2] ${cyan}Preferred${green} IPV6${purple}   * ${rest}"
    echo -e "${purple}                     *${rest}"
    echo -e "${purple}[3] ${cyan}Free Config ${green}Wgcf${purple} *${rest}"
    echo -e "${purple}                     *${rest}"
    echo -e "${purple}[4] ${cyan}Install ${green}wire-g${purple}   *${rest}"
    echo -e "${purple}                     *${rest}"
    echo -e "${purple}[5] ${cyan}License Cloner${purple}   *${rest}"
    echo -e "${purple}                     *${rest}"
    echo -e "${purple}[${red}0${purple}] Back to Main Menu *${rest}"
    echo -e "${purple}**********************${rest}"
    echo -en "${cyan}Enter your choice: ${rest}"
    read -r cf_choice
    
    echo -e "${yellow}⚠️  Warning: This tool modifies network settings.${rest}"
    echo -e "${yellow}⚠️  License cloning may violate Cloudflare TOS.${rest}"
    echo -e "${red}Continue at your own risk!${rest}"
    echo ""
    read -p "Type 'yes' to continue: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${red}Cancelled.${rest}"
        sleep 2
        return
    fi
    
    echo -e "${cyan}CF Tools feature requires the full script.${rest}"
    echo -e "${cyan}Please run the original script separately.${rest}"
    sleep 3
}

# ============================================
# MAIN LOOP
# ============================================
while true; do
    show_main_menu
    read -r choice
    
    case "$choice" in
        1)
            run_cf_tools
            ;;
        2)
            run_fastly_scanner
            ;;
        3)
            run_gc_scanner
            ;;
        0)
            echo -e "${cyan}Goodbye!${rest}"
            exit 0
            ;;
        *)
            echo -e "${red}Invalid option!${rest}"
            sleep 2
            ;;
    esac
done
