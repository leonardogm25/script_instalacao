#!/bin/bash

LOGFILE="/var/log/script_instalacao.log"
exec &> >(tee -a "$LOGFILE")

# Função para exibir o menu e capturar a escolha do usuário
exibir_menu() {
    echo "Script para instalação e configuração"
    echo "Criado por Leonardo Guedes - TI"
    echo
    echo "1 - Configurações do Servidor (com Samba e Unifi)"
    echo "2 - Configurações para Desktop (sem Samba e Unifi, mas cria o usuário User)"
    echo "3 - Sair do Script e Reiniciar"
    read -p "Digite a opção desejada: " opcao
}

# Função para verificar se um programa está instalado
verificar_instalacao() {
    local programa=$1
    if command -v "$programa" &> /dev/null; then
        echo "$programa já está instalado."
        return 0
    else
        return 1
    fi
}

# Função para desabilitar o Wayland
desabilitar_wayland() {
    echo "Desabilitando o Wayland..."

    # Adiciona ou altera a configuração no arquivo gdm3
    sudo sed -i 's/^#WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf

    echo "Wayland desabilitado. Por favor, reinicie o sistema para que as alterações tenham efeito."
}

# Função para instalar Discord
instalar_discord() {
    verificar_instalacao discord && return
    echo "Instalando Discord..."

    # Baixa o pacote do Discord
    wget -q "https://discord.com/api/download?platform=linux&format=deb" -O discord.deb
    
    # Verifica se o pacote foi baixado com sucesso
    if [ -f "discord.deb" ]; then
        # Instala o pacote do Discord
        sudo dpkg -i discord.deb
        
        # Corrige dependências se necessário
        sudo apt-get install -f -y
        
        # Remove o pacote após a instalação
        rm discord.deb
        
        verificar_instalacao discord && echo "Discord instalado com sucesso!" || echo "Erro ao instalar Discord."
    else
        echo "Erro ao baixar o Discord. Verifique o link ou a conexão de rede."
    fi
}

# Função para instalar Brave Browser
instalar_brave() {
    verificar_instalacao brave-browser && return
    echo "Instalando Brave Browser..."
    sudo apt install curl -y
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install brave-browser -y
    verificar_instalacao brave-browser && echo "Brave Browser instalado com sucesso!" || echo "Erro ao instalar Brave Browser."
}

# Função para instalar Audio Recorder
instalar_audio_recorder() {
    verificar_instalacao audio-recorder && return
    echo "Instalando Audio Recorder..."
    sudo add-apt-repository ppa:audio-recorder/ppa -y
    sudo apt-get update
    sudo apt-get install audio-recorder -y
    verificar_instalacao audio-recorder && echo "Audio Recorder instalado com sucesso!" || echo "Erro ao instalar Audio Recorder."
}

# Função para instalar OnlyOffice
instalar_onlyoffice() {
    verificar_instalacao onlyoffice-desktopeditors && return
    echo "Instalando OnlyOffice..."

    # Verifica se o Snap está instalado
    if ! command -v snap &> /dev/null; then
        echo "Snap não está instalado. Instalando Snap..."
        sudo apt update
        sudo apt install snapd -y
        sudo systemctl enable --now snapd.socket
    fi

    # Instala o OnlyOffice via Snap
    sudo snap install onlyoffice-desktopeditors

    verificar_instalacao onlyoffice-desktopeditors && echo "OnlyOffice instalado com sucesso!" || echo "Erro ao instalar OnlyOffice."
}

# Função para criar usuários e definir senhas
criar_usuarios() {
    for user in Scan User; do
        if id "$user" &>/dev/null; then
            echo "O usuário $user já existe."
        else
            echo "Criando o usuário $user..."
            if [ "$user" == "User" ]; then
                sudo adduser --disabled-password --gecos "" --force-badname "$user"
                if [ $? -eq 0 ]; then
                    # Remove a senha do usuário User
                    sudo usermod --password "" "$user"
                    echo "Usuário $user criado com sucesso."
                else
                    echo "Erro ao criar o usuário $user."
                fi
            else
                sudo adduser --disabled-password --gecos "" "$user"
                if [ $? -eq 0 ]; then
                    echo "$user:scan@123" | sudo chpasswd
                    sudo usermod -aG sudo "$user"
                    echo -e "scan@123\nscan@123" | sudo smbpasswd -a -s "$user"
                    echo "Usuário $user criado com sucesso."
                else
                    echo "Erro ao criar o usuário $user."
                fi
            fi
        fi
    done
}

# Função para instalar Google Chrome
instalar_chrome() {
    verificar_instalacao google-chrome && return
    echo "Instalando Google Chrome..."
    wget -q -O google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    if [ -f "google-chrome.deb" ]; then
        sudo dpkg -i google-chrome.deb || sudo apt-get install -f -y
        rm google-chrome.deb
        verificar_instalacao google-chrome && echo "Google Chrome instalado com sucesso!" || echo "Erro ao instalar Google Chrome."
    else
        echo "Erro ao baixar o Google Chrome. Verifique o link ou a conexão de rede."
    fi
}

# Função para instalar Samba
instalar_samba() {
    verificar_instalacao samba && return
    echo "Instalando Samba..."
    sudo apt-get install samba -y
    verificar_instalacao samba && echo "Samba instalado com sucesso!" || echo "Erro ao instalar Samba."
}

# Função para instalar Unifi
instalar_unifi() {
    verificar_instalacao unifi && return
    echo "Instalando Unifi..."
    sudo apt-get install ca-certificates curl -y
    curl -sO https://get.glennr.nl/unifi/install/unifi-8.2.93.sh
    sudo bash unifi-8.2.93.sh -y
    verificar_instalacao unifi && echo "Unifi instalado com sucesso!" || echo "Erro ao instalar Unifi."
}

# Função para instalar VLC
instalar_vlc() {
    verificar_instalacao vlc && return
    echo "Instalando VLC..."
    sudo apt-get install vlc -y
    verificar_instalacao vlc && echo "VLC instalado com sucesso!" || echo "Erro ao instalar VLC."
}

# Função para instalar programas e usuários na opção 1
opcao1() {
    echo "Iniciando a instalação para a opção 1..."
    desabilitar_wayland
    sudo apt-get update -y && sudo apt-get upgrade -y
    instalar_chrome
    instalar_discord
    instalar_brave
    instalar_samba
    instalar_unifi
    criar_usuarios
    instalar_audio_recorder
    instalar_onlyoffice
    instalar_anydesk
}

# Função para instalar programas na opção 2
opcao2() {
    echo "Iniciando a instalação para a opção 2..."
    desabilitar_wayland
    sudo apt-get update -y && sudo apt-get upgrade -y
    instalar_chrome
    instalar_discord
    instalar_brave
    instalar_vlc
    criar_usuarios
    instalar_onlyoffice
    instalar_anydesk
}

# Função principal para controle do script
main() {
    while true; do
        exibir_menu
        case $opcao in
            1) opcao1 ;;
            2) opcao2 ;;
            3)
                echo "Saindo do script e reiniciando..."
                sudo init 6
                ;;
            *)
                echo "Opção inválida. Por favor, escolha novamente."
                ;;
        esac
    done
}

# Executa a função principal
main
