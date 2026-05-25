#!/bin/bash
# =============================================================================
# Caixa de Areia com Realidade Aumentada — instalador
# Projeto Colmeia UDESC (https://github.com/ColmeiaUDESC/Kinect-Livre)
#
# Compila e instala o stack:
#   - Vrui 8.0-002 (com patch OpenAL para Ubuntu 22.04+)
#   - Kinect 3.10 driver
#   - SARndbox 2.8
#
# Todo o source-code é vendorado em vendor/ — basta clonar o repo e rodar:
#   bash install.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Localização do repo (este script + assets vivem aqui)
# -----------------------------------------------------------------------------
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# Log: duplica toda saída para ~/caixa-de-areia-install.log (facilita debug se
# o terminal fechar). Só ativa se ainda não estiver dentro do tee (evita loop).
# -----------------------------------------------------------------------------
if [ -z "${_INSTALL_LOGGING:-}" ]; then
	export _INSTALL_LOGGING=1
	LOGFILE="$HOME/caixa-de-areia-install.log"
	echo "[log salvo em $LOGFILE]"
	exec > >(tee "$LOGFILE") 2>&1
fi

# Versões alvo (devem casar com os diretórios em vendor/)
VRUI_VERSION="8.0"
VRUI_RELEASE="002-MOD"
KINECT_VERSION="3.10"
SARNDBOX_VERSION="2.8"

VRUI_INSTALLDIR="/usr/local"
VRUI_MAKEDIR="$VRUI_INSTALLDIR/share/Vrui-$VRUI_VERSION/make"
SRC_DIR="$HOME/src"

# -----------------------------------------------------------------------------
# Verificações
# -----------------------------------------------------------------------------
if [ ! -d "$REPO/vendor/vrui" ]; then
	echo "ERRO: $REPO/vendor/vrui/ não encontrado. Você clonou o repo direito?"
	exit 1
fi

# -----------------------------------------------------------------------------
# Cache de sudo no início (evita pedir senha no meio)
# -----------------------------------------------------------------------------
echo "==> Esse script precisa de sudo. Informe sua senha:"
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

# -----------------------------------------------------------------------------
# 1) Dependências do sistema
# -----------------------------------------------------------------------------
echo
echo "==> [1/5] Instalando dependências do sistema..."
sudo apt-get update
sudo apt-get install -y \
	build-essential g++ python3 wget curl \
	libudev-dev libdbus-1-dev libusb-1.0-0-dev \
	zlib1g-dev libssl-dev \
	libpng-dev libjpeg-dev libtiff-dev \
	libasound2-dev libspeex-dev libopenal-dev \
	libv4l-dev libtheora-dev \
	libbluetooth-dev libfreetype6-dev \
	libxi-dev libxrandr-dev \
	mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev \
	libraw1394-dev \
	fonts-freefont-ttf

# .deb locais (libdc1394 versão 22, casada com Kinect 3.10)
sudo apt-get install -y "$REPO/vendor/libdc1394"/*.deb

# -----------------------------------------------------------------------------
# 2) Staging dos sources vendorados para ~/src/ (build local, rápido)
# -----------------------------------------------------------------------------
echo
echo "==> [2/5] Copiando source vendorado para $SRC_DIR/..."
mkdir -p "$SRC_DIR"

VRUI_DIR="$SRC_DIR/Vrui-$VRUI_VERSION-$VRUI_RELEASE"
KINECT_DIR="$SRC_DIR/Kinect-$KINECT_VERSION"
SARNDBOX_DIR="$SRC_DIR/SARndbox-$SARNDBOX_VERSION"

if [ ! -d "$VRUI_DIR" ]; then
	cp -r "$REPO/vendor/vrui" "$VRUI_DIR"
fi
if [ ! -d "$KINECT_DIR" ]; then
	cp -r "$REPO/vendor/kinect" "$KINECT_DIR"
fi
if [ ! -d "$SARNDBOX_DIR" ]; then
	cp -r "$REPO/vendor/sarndbox" "$SARNDBOX_DIR"
fi

# -----------------------------------------------------------------------------
# 3) Compilar e instalar o Vrui (delegado ao script auxiliar)
# -----------------------------------------------------------------------------
echo
echo "==> [3/5] Compilando o Vrui..."
bash "$REPO/scripts/build-vrui.sh" "$VRUI_INSTALLDIR"

# -----------------------------------------------------------------------------
# 4) Compilar e instalar o driver do Kinect
# -----------------------------------------------------------------------------
echo
echo "==> [4/5] Compilando o driver do Kinect..."
cd "$KINECT_DIR"
make -j"$(nproc)" VRUI_MAKEDIR="$VRUI_MAKEDIR"
sudo make VRUI_MAKEDIR="$VRUI_MAKEDIR" install
sudo make VRUI_MAKEDIR="$VRUI_MAKEDIR" installudevrules || \
	echo "(aviso) installudevrules falhou — comum no WSL, pode ignorar"

# -----------------------------------------------------------------------------
# 5) Compilar o SARndbox (sem make install — roda direto da pasta de build)
# -----------------------------------------------------------------------------
echo
echo "==> [5/5] Compilando o SARndbox..."
cd "$SARNDBOX_DIR"
make -j"$(nproc)" VRUI_MAKEDIR="$VRUI_MAKEDIR"

# -----------------------------------------------------------------------------
# Lançadores: script de execução + atalho na área de trabalho
# -----------------------------------------------------------------------------
echo
echo "==> Criando script de execução e atalho na área de trabalho..."

# Ícone do Colmeia (cacheado em ~/src para reuso)
if [ ! -f "$SRC_DIR/colmeia.jpg" ]; then
	curl -sL "https://avatars.githubusercontent.com/u/54866625?s=400&u=184d63b6c7ecc161f9ebbad8f6e7b32b2e600253&v=4" \
		-o "$SRC_DIR/colmeia.jpg"
fi

cat > "$SARNDBOX_DIR/RunSARndbox.sh" <<EOF
#!/bin/bash
cd "$SARNDBOX_DIR"
./bin/SARndbox -uhm -fpv
EOF
chmod a+x "$SARNDBOX_DIR/RunSARndbox.sh"

if [ -d "$HOME/Desktop" ]; then
	cat > "$HOME/Desktop/Caixa de Areia.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon=$SRC_DIR/colmeia.jpg
Exec=$SARNDBOX_DIR/RunSARndbox.sh
Name=Começa a Caixa de Areia
Comment=Caixa de Areia com Realidade Aumentada (Colmeia UDESC)
EOF
	chmod a+x "$HOME/Desktop/Caixa de Areia.desktop"
fi

echo
echo "============================================================"
echo " Instalação concluída."
echo
echo " Para rodar manualmente:"
echo "   $SARNDBOX_DIR/RunSARndbox.sh"
echo
echo " Próximo passo: calibrar o Kinect (ver README.md, seção 1.3)."
echo "============================================================"
