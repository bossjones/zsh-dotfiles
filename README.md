## Usage

[*chezmoi*](https://www.chezmoi.io/) is used to bootstrap dotfiles.

* One-line binary install
    ```sh
    sh -c "$(curl -fsLS chezmoi.io/get)" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git
    ```

# Re run
`chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git`

# Pull the latest changes from your repo
`chezmoi git pull -- --autostash --rebase`

<details>
    <summary>Notes</summary>

## Manual steps

</details>
