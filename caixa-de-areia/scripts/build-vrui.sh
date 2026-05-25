#!/bin/bash
# =============================================================================
# build-vrui.sh — compila e instala o Vrui a partir do source em $HOME/src/
#
# Esperado: $HOME/src/Vrui-8.0-002-MOD/ já existe (copiado pelo install.sh
# a partir de vendor/vrui/ no repo).
#
# Uso: bash build-vrui.sh [INSTALLDIR]
#   INSTALLDIR padrão: /usr/local
# =============================================================================

set -euo pipefail

VRUI_VERSION="8.0"
VRUI_RELEASE="002-MOD"
VRUI_DIR="$HOME/src/Vrui-${VRUI_VERSION}-${VRUI_RELEASE}"

VRUI_INSTALLDIR="${1:-/usr/local}"
NUM_CPUS=$(nproc)

if [ ! -d "$VRUI_DIR" ]; then
	echo "ERRO: $VRUI_DIR não existe. Rode o install.sh, não esse script direto."
	exit 1
fi

# Sudo é necessário se a instalação for fora do home do usuário
INSTALL_NEEDS_SUDO=1
[[ "$VRUI_INSTALLDIR" = "$HOME"* ]] && INSTALL_NEEDS_SUDO=0

# Path do diretório de make do Vrui (com shim Vrui-<versão> se necessário)
VRUI_MAKEDIR="$VRUI_INSTALLDIR/share/Vrui-$VRUI_VERSION/make"
[[ "$VRUI_INSTALLDIR" = *"Vrui-$VRUI_VERSION"* ]] && \
	VRUI_MAKEDIR="$VRUI_INSTALLDIR/share/make"

cd "$VRUI_DIR"

echo "==> Compilando Vrui em $NUM_CPUS CPUs (INSTALLDIR=$VRUI_INSTALLDIR)..."
make -j"$NUM_CPUS" INSTALLDIR="$VRUI_INSTALLDIR"

echo "==> Instalando Vrui em $VRUI_INSTALLDIR..."
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	sudo make INSTALLDIR="$VRUI_INSTALLDIR" install
else
	make INSTALLDIR="$VRUI_INSTALLDIR" install
fi

echo "==> Instalando regras de permissão de dispositivos..."
sudo make INSTALLDIR="$VRUI_INSTALLDIR" installudevrules || \
	echo "(aviso) installudevrules falhou — comum no WSL, pode ignorar"

echo "==> Compilando programas de exemplo do Vrui..."
cd ExamplePrograms
make -j"$NUM_CPUS" VRUI_MAKEDIR="$VRUI_MAKEDIR" INSTALLDIR="$VRUI_INSTALLDIR"

echo "==> Instalando programas de exemplo do Vrui..."
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	sudo make VRUI_MAKEDIR="$VRUI_MAKEDIR" INSTALLDIR="$VRUI_INSTALLDIR" install
else
	make VRUI_MAKEDIR="$VRUI_MAKEDIR" INSTALLDIR="$VRUI_INSTALLDIR" install
fi

echo "==> Build do Vrui concluído."
