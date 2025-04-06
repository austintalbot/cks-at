#!/bin/bash


export LC_ALL=C
install_kubecolor() {
    echo "Installing kubecolor..."
    OS="$(uname | tr '[:upper:]' '[:lower:]')"
    if [[ "$OS" == "darwin"* ]]; then
        echo "macOS detected, skipping kubecolor installation"
        return
    fi

    apt update -y
    apt install -y wget tar git bash-completion sudo file neovim
    apt upgrade -y

    #

    wget https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
    tar -xvf kubecolor_0.5.0_linux_amd64.tar.gz
    chmod +x kubecolor
    sudo mv kubecolor /usr/local/bin/
    rm kubecolor_0.5.0_linux_amd64.tar.gz
}

install_krew() {
    echo "Installing krew..."
    (
        set -x
        cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
    )

    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    kubectl krew install cyclonus neat np-viewer sniff view-secret view-utilization view-webhook who-can

    # Add Krew to PATH in .bashrc if not already present
    if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >>~/.bashrc
    fi
}

install_yq() {
    echo "Installing yq..."
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    chmod +x /usr/bin/yq
}
setup_aliases_and_completion() {
    echo "Setting up aliases and completion..."

    # Ensure bash-completion is sourced
  if ! grep -q '/usr/share/bash-completion/bash_completion' ~/.bashrc ; then
    echo 'if [ -f /usr/share/bash-completion/bash_completion ]; then' >>~/.bashrc
    echo '    . /usr/share/bash-completion/bash_completion' >>~/.bashrc
    echo 'fi' >>~/.bashrc

    # Check if kubectl completion is already set u
    echo "source /usr/share/bash-completion/bash_completion" >>~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

    fi

    # Add kubectl completion
    if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
        echo "source <(kubectl completion bash)" >>~/.bashrc
    fi

    # Add kubecolor completion
    if ! grep -q 'source <(kubecolor completion bash)' ~/.bashrc; then
        echo "source <(kubecolor completion bash)" >>~/.bashrc
    fi

    # Add alias for kubectl
    if ! grep -q 'alias k=kubectl' ~/.bashrc; then
        echo "alias k=kubectl" >>~/.bashrc
    fi

    # Add alias for kubectl to kubecolor
    if ! grep -q 'alias kubectl=kubecolor' ~/.bashrc; then
        echo "alias kubectl=kubecolor" >>~/.bashrc
    fi

    # Add kubectl completion for alias 'k'
    if ! grep -q 'complete -o default -F __start_kubectl k' ~/.bashrc; then
        echo "complete -o default -F __start_kubectl k" >>~/.bashrc
    fi

    # Add crictl completion
    if ! grep -q 'source <(crictl completion bash)' ~/.bashrc; then
        echo "source <(crictl completion bash)" >>~/.bashrc
    fi

    # Reload .bashrc to apply changes
    source ~/.bashrc
}

main() {
    install_kubecolor
    install_krew
    install_yq
    setup_aliases_and_completion
}

main