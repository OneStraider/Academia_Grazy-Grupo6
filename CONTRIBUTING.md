# Como contribuir — Grupo 6

Guia rápido do dia a dia. O fluxo completo e os porquês estão em
[`docs/GITFLOW.md`](docs/GITFLOW.md).

---

## Configuração inicial (uma vez por máquina)

```bash
git clone https://github.com/OneStraider/Academia_Grazy-Grupo6.git
cd Academia_Grazy-Grupo6

git config user.name "Seu Nome"
git config user.email "seu-email@exemplo.com"

git checkout develop
```

Use **o mesmo e-mail cadastrado no seu GitHub** — é assim que os commits ficam
vinculados ao seu perfil e a contribuição de cada um fica visível na avaliação.

---

## Rotina de trabalho

```bash
# 1. Atualize develop
git checkout develop
git pull origin develop

# 2. Crie sua branch
git checkout -b feature/REQ-XX-descricao-curta

# 3. Trabalhe, comitando aos poucos
git status
git add caminho/do/arquivo.dart
git commit -m "feat(modulo): descrição no imperativo"

# 4. Sincronize antes de enviar
git checkout develop && git pull origin develop
git checkout feature/REQ-XX-descricao-curta
git merge develop

# 5. Envie
git push -u origin feature/REQ-XX-descricao-curta
```

Depois abra o Pull Request no GitHub com base em `develop`.

---

## Checklist antes de abrir o Pull Request

- [ ] O código compila (`flutter analyze` sem erros novos)
- [ ] O app roda (`flutter run`)
- [ ] Fiz merge da `develop` na minha branch e resolvi os conflitos
- [ ] Mensagens de commit no padrão `tipo(escopo): descrição`
- [ ] Nenhum segredo, `.env`, chave ou dado real de aluno no diff
- [ ] Nenhum arquivo de IDE (`.idea/`, `.vscode/`) ou `build/` no diff
- [ ] O título do PR cita o requisito (ex: `REQ-03 — Ficha de treino personalizada`)

---

## Revisando o PR de um colega

Revisar é parte do trabalho, não favor. Ao revisar:

- Rode a branch na sua máquina antes de aprovar
- Comente o que não entendeu — dúvida de leitor é problema de código
- Aprove só o que você conseguiria explicar na apresentação
- Prefira sugestão a exigência: "e se usássemos X?" resolve mais rápido que "está errado"

---

## Comandos que salvam

```bash
git status                       # onde eu estou e o que mudou
git log --oneline --graph --all  # o histórico desenhado
git diff                         # o que mudei e ainda não adicionei
git diff --staged                # o que já está no stage

git restore arquivo.dart         # desfaz mudanças não commitadas do arquivo
git restore --staged arquivo.dart # tira do stage, mantém a mudança

git stash                        # guarda mudanças temporariamente
git stash pop                    # traz de volta

git branch                       # branches locais
git branch -a                    # locais + remotas
git switch develop               # troca de branch (equivalente ao checkout)
```

---

## Se der problema

| Situação | O que fazer |
|---|---|
| Comitei na branch errada | `git log -1` para copiar o hash, `git reset --soft HEAD~1`, troque de branch, comite de novo |
| Quero desfazer o último commit local (ainda sem push) | `git reset --soft HEAD~1` mantém as mudanças; `--hard` descarta tudo |
| Conflito no merge | Abra os arquivos marcados, escolha o conteúdo correto, apague os `<<<<<<<`, `=======`, `>>>>>>>`, depois `git add` e `git commit` |
| `push` rejeitado | Alguém enviou antes: `git pull origin sua-branch` e tente de novo |
| Me perdi de vez | **Não use `--force`.** Chame o grupo antes de qualquer coisa. |
