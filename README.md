<p align="center">
    <img src="https://avatars.githubusercontent.com/u/54866625?s=400&u=184d63b6c7ecc161f9ebbad8f6e7b32b2e600253&v=4" alt="Logo" width="160" height="160">
  <h1 align="center">Kinect Livre</h1>
</p>

## :dart: Conceito

> Utilização do sensor de movimentos e profundidade [Kinect](https://pt.wikipedia.org/wiki/Kinect) para a implementação e desenvolvimento de projetos para exposição.

## 💡 Objetivos

> Trazer atenção não só a uma tecnologia muito interessante, mas em como o Software Livre ajudou a manter ela viva com drivers, bibliotecas e projetos abertos.

## Projetos

- **[Caixa de Areia com Realidade Aumentada](caixa-de-areia/)** [100% — funcionando]
- **Piano em Qualquer Lugar** [10%]

---

# 🏖️ Caixa de Areia com Realidade Aumentada

## 🤔 O que é?
Projeção do relevo de uma caixa contendo areia em tempo real com simulação de fluidos nesse relevo. Feito utilizando um Kinect posicionado ortogonalmente acima da caixa e ao seu lado um projetor, ambos apontando para a areia dessa caixa.

## 🫥 Inspiração
A ideia inicial surgiu ao assistir vídeos curtos sobre projetos semelhantes em redes sociais. Após pesquisas, decidimos implementar o trabalho desenvolvido por UC Davis' W.M. Keck Center for Active Visualization in the Earth Sciences (KeckCAVES), UC Davis Tahoe Environmental Research Center, Lawrence Hall of Science, ECHO Lake Aquarium and Science Center.
É possível encontrar o projeto original no [site oficial](https://web.cs.ucdavis.edu/~okreylos/ResDev/SARndbox/) do Oliver Kreylos, junto com mais informações relacionadas a origem do projeto e aprofundamento no tutorial de instalação.

## 🎒 Materiais
- Computador (Recomendado: placa de vídeo GeForce GTX 1060, processador Intel Core i5 e 4GB de RAM)
- Kinect 1, modelo usado no Xbox 360 (1414, 1473 ou Kinect for Windows)
- Projetor de tela, preferencialmente com resolução nativa de 4:3
- Caixa retangular com proporção 4:3
- Suporte para o Kinect e o projetor — ambos centralizados acima da caixa, apontados pra ela
- Areia tratada

## 📂 Estrutura do projeto

```
caixa-de-areia/
├── install.sh              ← entry point: roda tudo do zero
├── docs/manual.pdf         ← manual original do projeto
├── scripts/
│   └── build-vrui.sh       ← compila o Vrui (chamado pelo install.sh)
└── vendor/                 ← source-code completo, modificável
    ├── vrui/               ← Vrui 8.0-002 (com patch OpenAL pra Ubuntu 22.04+)
    ├── sarndbox/           ← SARndbox 2.8 — visualização e simulação
    ├── kinect/             ← Kinect 3.10 — driver
    └── libdc1394/          ← .deb files do libdc1394-22
```

Quer mexer na visualização, cores, física dos fluidos? Edita `vendor/sarndbox/`.
Quer mexer no driver do Kinect? `vendor/kinect/`. Manda PR.

### Modificações em relação ao upstream
- **`vendor/vrui/Vrui/SoundContext.h`**: as forward declarations de `ALCdevice` e `ALCcontext` foram trocadas pra compatibilizar com o cabeçalho moderno do OpenAL (`libopenal-dev` no Ubuntu 22.04+). Sem isso o Vrui não compila em distribuições recentes.

## 🤓 Instalação

### 1.1 - Sistema operacional
**Ubuntu 24.04 LTS** (testado e funcionando). Versões antigas como Linux Mint 19.3 com MATE também rodam, mas exigem ajustes manuais.

> 💡 **WSL2 (Windows)**: dá pra compilar tudo dentro do WSL pra desenvolvimento, mas o Kinect só funciona via `usbipd-win` e mesmo assim a latência costuma ser insuficiente pra projeção em tempo real. Use **Linux nativo** pra exposição/uso real.

### 1.2 - Rodar o script de instalação
Clone o repo e dispare o `install.sh`:

```bash
git clone https://github.com/ColmeiaUDESC/Kinect-Livre.git
cd Kinect-Livre/caixa-de-areia
bash install.sh
```

O script:
1. Pede sua senha do sudo (uma vez no início)
2. Instala dependências do sistema via `apt`
3. Copia `vendor/` pra `~/src/` (build local, rápido)
4. Compila Vrui, driver do Kinect e SARndbox (uns 20–30 minutos)
5. Cria `RunSARndbox.sh` e atalho na área de trabalho

### 1.3 - Calibre o Kinect
- Com o Kinect já acima da caixa, execute `RawKinectViewer -o` no terminal.
- Verifique se a câmera está alinhada com a caixa.
- Botão direito do mouse → `average frames`.
- Tecla `1` → `Extract Planes`. Coloque o mouse num canto da caixa, segure `1`, arraste até o canto oposto e solte `1`.
- Tecla `2` → `Measure 3D points`. Aperte `2` em cada canto, nessa ordem: inferior esquerdo, inferior direito, superior esquerdo, superior direito.
- O terminal deve mostrar algo como:
```
Camera-space plane equation: x * (0.00532502, -0.0501786, 0.998726) = -115.296
(            -46.3606,             -37.7409,             -117.027)
(             32.4776,              -35.279,             -117.351)
(             -47.265,               39.513,             -112.917)
(             28.5548,              41.5887,             -113.528)
```
- Copie e cole essas linhas em `~/src/SARndbox-2.8/etc/SARndbox-2.8/BoxLayout.txt`.
- Apague o texto antes do primeiro parêntese da primeira linha e troque o `=` por uma vírgula. Deve ficar:
```
   (0.00532502, -0.0501786, 0.998726), -115.296
(            -46.3606,             -37.7409,             -117.027)
(             32.4776,              -35.279,             -117.351)
(             -47.265,               39.513,             -112.917)
(             28.5548,              41.5887,             -113.528)
```
- Salve, feche o arquivo e o `RawKinectViewer`.

### 1.4 - Usando a caixa
- O relevo muda em tempo real — mexa na areia e veja o mapa mudando.
- Pra iniciar: clique no ícone na área de trabalho (logo do Colmeia) ou rode `~/src/SARndbox-2.8/RunSARndbox.sh`.
- Pra fazer chover em um ponto: abra bem a mão sobre a caixa, numa altura um pouco maior que ela (sem chegar perto da câmera).
- Tecla `1` → chove na caixa inteira.
- Tecla `2` → para a chuva.
- Tecla `Esc` → fecha o sistema.

---

## 🐝 Sobre o Colmeia
### Grupo de extensão em software e hardware livre
> Com o objetivo da disseminação de conhecimento em software e hardware livres o Colmeia ministra aulas e minicursos de diversos temas, visitamos escolas e outras universidades com o objetivo de apresentar o Colmeia e toda a ideologia do grupo, além disso temos múltiplos outros projetos internos variados.

<sub> <strong>Siga o Colmeia nas redes sociais para acompanhar mais conteúdos: </strong> <br>
[<img src = "https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white">](https://github.com/ColmeiaUDESC)
[![TikTok](https://img.shields.io/badge/TikTok-%23000000.svg?logo=TikTok&style=for-the-badge&logoColor=white)](https://www.tiktok.com/@colmeiaudesc)
[<img src = "https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white">](https://www.facebook.com/colmeiaudesc/)
[<img src = "https://img.shields.io/badge/instagram-%23E4405F.svg?&style=for-the-badge&logo=instagram&logoColor=white">](https://www.instagram.com/colmeiaudesc/)
[<img src="https://img.shields.io/badge/linkedin-%230077B5.svg?&style=for-the-badge&logo=linkedin&logoColor=white" />](https://www.linkedin.com/company/colmeiaudesc)
[![Discord Badge](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/yZZsV4xABZ)
[![Youtube Badge](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/channel/UC51KrWL94AfGxI_4l_E7uzA)
</sub>

## 🤝 Como contribuir?
Viu alguma coisa errada ou quer propor uma melhoria? Pode criar uma issue explicando o seu caso, ou então criar um fork desse repositório, arrumar o que precisar e criar um pull request explicando o que foi mudado e por quê.

- Editou source em `caixa-de-areia/vendor/`? Rode `install.sh` de novo — é idempotente, recompila só o que mudou.
- Build quebrou após editar? Veja a seção *Modificações em relação ao upstream* — pode ser que o ajuste atropelou um patch.
- Não tenha medo de pedir ajuda. Pode entrar no nosso [Discord](https://discord.gg/yZZsV4xABZ), procurar a seção sobre esse projeto e mandar uma mensagem.
