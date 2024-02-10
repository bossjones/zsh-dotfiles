K3D_BIN="$(which k3d)"

if [ -x "$K3D_BIN" ]; then
    if command -v k3d &>/dev/null; then
        source <(k3d completion zsh)
    fi
fi
