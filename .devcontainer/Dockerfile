FROM ghcr.io/qmk/qmk_cli:latest

ARG QMK_VERSION=0.22.14
ENV QMK_VERSION=${QMK_VERSION}

# 必要なパッケージのインストール
RUN apt update && apt install -y \
    zsh \
    curl \
    fonts-powerline \
    vim \
    build-essential

# zshをデフォルトのシェルに設定
RUN chsh -s $(which zsh)

# Starshipのインストール
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Oh My Zshのインストール
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" --unattended

# Starship設定を.zshrcに追加
RUN echo 'eval "$(starship init zsh)"' >> /root/.zshrc

# StarshipのPastel Powerlineプリセットを適用
RUN mkdir -p /root/.config && starship preset pastel-powerline -o /root/.config/starship.toml

# コンテナ内のデフォルトシェルをzshに変更
CMD ["zsh"]

WORKDIR /workspaces/keyball-custom