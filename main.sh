#!/bin/bash

declare -A COLORS=(
    ["INFO"]="\033[1;36m"
    ["WARN"]="\033[1;33m"
    ["ERROR"]="\033[1;31m"
    ["SUCCESS"]="\033[1;32m"
    ["TITLE"]="\033[1;34m"
    ["PROMPT"]="\033[1;33m"
    ["RESET"]="\033[0m"
)

declare -A EMOJIS=(
    ["INFO"]="ℹ️"
    ["WARN"]="⚠️"
    ["ERROR"]="❌"
    ["SUCCESS"]="✅"
    ["TITLE"]="✨"
    ["PROMPT"]="👉"
    ["SSL"]="🔐"
    ["CERT"]="📄"
    ["SSH"]="🔒"
    ["LOG"]="📜"
    ["EXIT"]="👋"
)

readonly TOKEN_PATH="$HOME/.proxy_token"
readonly PROXY_EXECUTABLE="/usr/local/bin/proxy"
readonly LOG_PATH="/var/log"
readonly SYSTEMD_SERVICE_PATH="/etc/systemd/system"
readonly DEFAULT_BUFFER_SIZE=32768
readonly DEFAULT_HTTP_RESPONSE="DTunnel"
readonly MIN_PORT=1
readonly MAX_PORT=65535

print_message() {
    local type="$1"
    local message="$2"
    echo -e "${COLORS[$type]}${EMOJIS[$type]} $message${COLORS[RESET]}" >&2
}

format_prompt() {
    echo -e "${COLORS[PROMPT]}${EMOJIS[PROMPT]} $1${COLORS[RESET]}"
}

read_input() {
    local prompt_text="$1"
    local default_value="${2:-}"
    local value

    if [[ -n "$default_value" ]]; then
        read -rp "$(format_prompt "$prompt_text") [$default_value]: " value
        echo "${value:-$default_value}"
    else
        read -rp "$(format_prompt "$prompt_text"): " value
        echo "$value"
    fi
}

confirm_action() {
    local default_answer="${1:-n}"
    local question="$2"
    local answer

    while true; do
        read -rp "$question (s/n) [$default_answer]: " answer
        answer=${answer:-$default_answer}
        case "${answer,,}" in
        s | sim) return 0 ;;
        n | nao | não) return 1 ;;
        *) print_message "ERROR" "Resposta inválida. Use 's' para sim ou 'n' para não." ;;
        esac
    done
}

wait_for_enter() {
    read -rp "$(format_prompt 'Pressione Enter para continuar...')" _
}

get_service_name() {
    echo "proxy-$1"
}

get_service_file_path() {
    echo "$SYSTEMD_SERVICE_PATH/$(get_service_name "$1").service"
}

get_log_file_path() {
    echo "$LOG_PATH/proxy-$1.log"
}

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] || return 1
    ((port >= MIN_PORT && port <= MAX_PORT))
}

is_port_in_use() {
    local port="$1"
    ss -tuln | grep -q ":$port "
}

is_service_running() {
    local service_name
    service_name=$(get_service_name "$1")
    systemctl is-active --quiet "$service_name"
}

read_token_from_file() {
    [[ -f "$TOKEN_PATH" ]] && cat "$TOKEN_PATH" || echo ""
}

validate_access_token() {
    "$PROXY_EXECUTABLE" --token "$1" --validate >/dev/null 2>&1
}

prompt_for_token_if_missing() {
    local token
    token=$(read_token_from_file)

    if [[ -z "$token" ]]; then
        clear
        print_message "WARN" "Token de acesso não encontrado."

        while true; do
            token=$(read_input "Por favor, insira seu token")
            if validate_access_token "$token"; then
                echo "$token" >"$TOKEN_PATH"
                print_message "SUCCESS" "Token salvo em $TOKEN_PATH."
                return
            fi
            print_message "ERROR" "Token inválido. Por favor, forneça um token válido."
        done
    fi
}

ask_for_port() {
    local operation="$1"
    local port

    while true; do
        port=$(read_input "Porta")

        if ! is_valid_port "$port"; then
            print_message "ERROR" "Porta inválida. Deve estar entre $MIN_PORT e $MAX_PORT."
            continue
        fi

        if [[ "$operation" == "start" ]] && is_port_in_use "$port"; then
            print_message "ERROR" "Porta $port já está em uso."
            continue
        fi

        if [[ "$operation" != "start" ]] && ! is_service_running "$port"; then
            print_message "ERROR" "Nenhum serviço ativo na porta $port."
            continue
        fi

        echo "$port"
        return
    done
}

build_service_file() {
    local port="$1"
    local token="$2"
    local ssl_enabled="$3"
    local ssl_cert_path="$4"
    local ssh_only_flag="$5"
    local http_response="$6"
    local service_file_path

    service_file_path=$(get_service_file_path "$port")

    cat >"$service_file_path" <<EOF
[Unit]
Description=DTunnel Proxy Server na porta $port

[Service]
ExecStart=$PROXY_EXECUTABLE --token=$token --port=$port$ssl_enabled $ssl_cert_path $ssh_only_flag --buffer-size=$DEFAULT_BUFFER_SIZE --response=$http_response --domain --log-file=$(get_log_file_path "$port")
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

start_proxy_service() {
    local port ssl_enabled="" ssl_cert_path="" ssh_only_flag="" http_response token

    port=$(ask_for_port "start") || return
    token=$(read_token_from_file)

    if confirm_action "n" "$(format_prompt "${EMOJIS[SSL]} Deseja habilitar SSL?")"; then
        ssl_enabled=":ssl"
        if ! confirm_action "s" "$(format_prompt "${EMOJIS[CERT]} Usar certificado interno?")"; then
            ssl_cert_path=$(read_input "Caminho do certificado SSL")
            [[ -n "$ssl_cert_path" ]] && ssl_cert_path="--cert=$ssl_cert_path"
        fi
    fi

    http_response=$(read_input "Resposta HTTP padrão" "$DEFAULT_HTTP_RESPONSE")

    if confirm_action "n" "$(format_prompt "${EMOJIS[SSH]} Habilitar modo somente SSH?")"; then
        ssh_only_flag="--ssh-only"
    fi

    build_service_file "$port" "$token" "$ssl_enabled" "$ssl_cert_path" "$ssh_only_flag" "$http_response"

    systemctl daemon-reload
    systemctl start "$(get_service_name "$port")"
    systemctl enable "$(get_service_name "$port")"

    print_message "SUCCESS" "Proxy iniciado na porta $port."
    wait_for_enter
}

restart_proxy_service() {
    local port service_name
    port=$(ask_for_port) || return
    service_name=$(get_service_name "$port")
    systemctl restart "$service_name"

    print_message "SUCCESS" "Proxy na porta $port reiniciado."
    wait_for_enter
}

stop_proxy_service() {
    local port service_name service_file_path
    port=$(ask_for_port) || return
    service_name=$(get_service_name "$port")
    service_file_path=$(get_service_file_path "$port")

    systemctl stop "$service_name"
    systemctl disable "$service_name"
    rm -f "$service_file_path"
    systemctl daemon-reload

    print_message "SUCCESS" "Proxy na porta $port foi encerrado."
    wait_for_enter
}

show_proxy_logs() {
    local port proxy_log_file
    port=$(ask_for_port) || return
    proxy_log_file=$(get_log_file_path "$port")

    if [[ ! -f "$proxy_log_file" ]]; then
        print_message "ERROR" "Arquivo de log não encontrado."
        wait_for_enter
        return
    fi

    trap 'break' INT
    while :; do
        clear
        cat "$proxy_log_file"
        echo -e "\nPressione ${COLORS[WARN]}Ctrl+C${COLORS[RESET]} para retornar ao menu."
        sleep 1
    done
    trap - INT
}

list_active_proxies() {
    systemctl list-units --type=service --state=running | grep -oE 'proxy-[0-9]+' | cut -d'-' -f2 | tr '\n' ' '
}

display_menu() {
    local active_ports
    echo -e "${COLORS[TITLE]}╔═════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║${COLORS[SUCCESS]}      DTunnel Proxy Menu     ${COLORS[RESET]}${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║═════════════════════════════║${COLORS[RESET]}"

    active_ports=$(list_active_proxies)
    if [[ -n "$active_ports" ]]; then
        echo -e "${COLORS[TITLE]}║${COLORS[SUCCESS]}Em uso:${COLORS[WARN]} $(printf "%-20s ${COLORS[TITLE]}║" "$active_ports")${COLORS[RESET]}"
        echo -e "${COLORS[TITLE]}║═════════════════════════════║${COLORS[RESET]}"
    fi

    echo -e "${COLORS[TITLE]}║${COLORS[INFO]}[${COLORS[SUCCESS]}01${COLORS[INFO]}] ${COLORS[SUCCESS]}• ${COLORS[ERROR]}ABRIR PORTA           ${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║${COLORS[INFO]}[${COLORS[SUCCESS]}02${COLORS[INFO]}] ${COLORS[SUCCESS]}• ${COLORS[ERROR]}FECHAR PORTA          ${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║${COLORS[INFO]}[${COLORS[SUCCESS]}03${COLORS[INFO]}] ${COLORS[SUCCESS]}• ${COLORS[ERROR]}REINICIAR PORTA       ${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║${COLORS[INFO]}[${COLORS[SUCCESS]}04${COLORS[INFO]}] ${COLORS[SUCCESS]}• ${COLORS[ERROR]}VER LOG DA PORTA      ${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}║${COLORS[INFO]}[${COLORS[SUCCESS]}00${COLORS[INFO]}] ${COLORS[ERROR]}• ${COLORS[WARN]}SAIR                  ${COLORS[TITLE]}║${COLORS[RESET]}"
    echo -e "${COLORS[TITLE]}╚═════════════════════════════╝${COLORS[RESET]}"
}

main() {
    prompt_for_token_if_missing

    while true; do
        clear
        display_menu
        local choice
        choice=$(read_input "Digite sua opção")

        case "$choice" in
        1 | 01) start_proxy_service ;;
        2 | 02) stop_proxy_service ;;
        3 | 03) restart_proxy_service ;;
        4 | 04) show_proxy_logs ;;
        0 | 00)
            print_message "EXIT" "Saindo. Até logo!"
            exit 0
            ;;
        *)
            print_message "ERROR" "Opção inválida."
            wait_for_enter
            ;;
        esac
    done
}

main
