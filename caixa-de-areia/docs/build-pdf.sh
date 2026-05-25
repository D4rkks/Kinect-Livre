#!/bin/bash
# =============================================================================
# build-pdf.sh — gera docs/manual.pdf a partir de docs/manual.md
#
# Na primeira vez instala pandoc + texlive-xetex + poppler-utils (~700 MB).
# Na primeira vez também extrai as fotos do manual.pdf antigo (se existir),
# colocando-as em docs/photos/ pra reutilização.
#
# Uso:
#   bash docs/build-pdf.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# -----------------------------------------------------------------------------
# 1) Verificar e instalar dependências
# -----------------------------------------------------------------------------
NEED_INSTALL=""
command -v pandoc   >/dev/null 2>&1 || NEED_INSTALL="$NEED_INSTALL pandoc"
command -v xelatex  >/dev/null 2>&1 || NEED_INSTALL="$NEED_INSTALL texlive-xetex texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra texlive-lang-portuguese"
command -v pdfimages >/dev/null 2>&1 || NEED_INSTALL="$NEED_INSTALL poppler-utils"
command -v convert  >/dev/null 2>&1 || NEED_INSTALL="$NEED_INSTALL imagemagick"

if [ -n "$NEED_INSTALL" ]; then
	echo "==> Instalando tooling (~700 MB na primeira vez):$NEED_INSTALL"
	sudo apt-get update
	# shellcheck disable=SC2086
	sudo apt-get install -y $NEED_INSTALL
fi

# -----------------------------------------------------------------------------
# 2) Garantir docs/photos/ e extrair fotos do manual.pdf antigo se necessário
# -----------------------------------------------------------------------------
mkdir -p photos

# Nomes esperados pelas referências no manual.md
EXPECTED_PHOTOS=(
	"01-original-uc-davis.jpg"
	"02-mark-i.jpg"
	"03-mark-i-casa-branca.jpg"
)

ALL_PRESENT=1
for p in "${EXPECTED_PHOTOS[@]}"; do
	[ -f "photos/$p" ] || ALL_PRESENT=0
done

if [ $ALL_PRESENT -eq 0 ]; then
	if [ -f manual.pdf ]; then
		echo "==> Extraindo fotos do manual.pdf antigo pra docs/photos/..."
		EXTRACT_TMP=$(mktemp -d)
		pdfimages -j manual.pdf "$EXTRACT_TMP/img" || \
			pdfimages    manual.pdf "$EXTRACT_TMP/img"

		# Pega os 3 maiores arquivos extraídos (são as fotos; ícones e logos são pequenos)
		readarray -t LARGEST < <(ls -S "$EXTRACT_TMP"/*.jpg "$EXTRACT_TMP"/*.png "$EXTRACT_TMP"/*.ppm 2>/dev/null | head -3)

		if [ "${#LARGEST[@]}" -ge 3 ]; then
			# As fotos no PDF aparecem nas páginas 5, 6, 7 nessa ordem:
			# Fig 1: original UC Davis, Fig 2: Mark I, Fig 3: Casa Branca
			# pdfimages extrai por ordem de aparição → primeira maior = primeira foto
			# Re-ordena por nome (que segue ordem de página) e usa as 3 primeiras
			readarray -t IN_ORDER < <(ls "$EXTRACT_TMP"/*.{jpg,png,ppm} 2>/dev/null | \
				xargs -I {} bash -c 'echo "$(stat -c%s "{}") {}"' | \
				sort -rn | head -3 | awk '{print $2}' | sort)

			for i in 0 1 2; do
				SRC="${IN_ORDER[$i]:-}"
				DST="photos/${EXPECTED_PHOTOS[$i]}"
				if [ -n "$SRC" ] && [ -f "$SRC" ]; then
					# Se for .ppm, converte pra jpg
					case "$SRC" in
						*.ppm) convert "$SRC" "$DST" ;;
						*)     cp "$SRC" "$DST" ;;
					esac
					echo "    photos/${EXPECTED_PHOTOS[$i]}  ←  $(basename "$SRC")"
				fi
			done
		else
			echo "    AVISO: não achei 3 imagens grandes no PDF — criando placeholders"
		fi

		rm -rf "$EXTRACT_TMP"
	else
		echo "==> manual.pdf antigo não existe — criando placeholders"
	fi
fi

# -----------------------------------------------------------------------------
# 3) Criar placeholders pra qualquer foto que ainda não exista
# -----------------------------------------------------------------------------
PLACEHOLDER_LABELS=(
	"FOTO: Caixa montada\\n(vista geral)"
	"FOTO: Setup completo\\n(Kinect e projetor sobre a caixa)"
	"FOTO: Sistema em uso\\n(caixa com projeção)"
)

for i in 0 1 2; do
	DST="photos/${EXPECTED_PHOTOS[$i]}"
	if [ ! -f "$DST" ]; then
		LABEL="${PLACEHOLDER_LABELS[$i]}"
		convert -size 1200x800 \
			gradient:lightgray-gray \
			-gravity center \
			-font DejaVu-Sans-Bold -pointsize 48 -fill black \
			-annotate +0+0 "$LABEL" \
			-bordercolor "#666" -border 3 \
			"$DST"
		echo "    photos/${EXPECTED_PHOTOS[$i]}  (placeholder gerado)"
	fi
done

# -----------------------------------------------------------------------------
# 4) Gerar o PDF
# -----------------------------------------------------------------------------
echo "==> Gerando manual.pdf via pandoc + xelatex..."
pandoc manual.md \
	-o manual.pdf \
	--pdf-engine=xelatex \
	--toc \
	--toc-depth=3 \
	-V geometry:margin=2.5cm \
	-V linkcolor:blue \
	-V mainfont="DejaVu Serif" \
	-V sansfont="DejaVu Sans" \
	-V monofont="DejaVu Sans Mono" \
	--highlight-style=tango

echo
echo "============================================================"
echo " ✓ manual.pdf gerado em $(pwd)/manual.pdf"
echo "   $(du -h manual.pdf | cut -f1) — $(pdfinfo manual.pdf 2>/dev/null | grep Pages | awk '{print $2}') páginas"
echo
echo " Pra trocar uma foto: substitui o arquivo em docs/photos/"
echo " (mantém o mesmo nome) e roda esse script de novo."
echo "============================================================"
