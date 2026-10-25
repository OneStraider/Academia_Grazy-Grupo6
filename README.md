# Academia Grazy - Grupo 6

Aplicativo acadêmico em Flutter, Dart e SQLite, organizado pelo **Plano de Ação v2 (28/09/2026)**. O padrão visual definido para o app é o modelo 2 (Clean Material).

## Escopo

Catálogo de exercícios; montagem, visualização e execução de treinos com feedback; avaliação física, IMC, anamnese e evolução; agendamento, cancelamento, check-in e vagas; login e permissões por perfil.

IA, financeiro, pagamentos, dashboard avançado, notificações, integrações externas e infraestrutura em nuvem estão fora do escopo do plano v2. Os documentos anteriores em `docs/` e `CONTRIBUTING.md` ainda descrevem o planejamento antigo; para esta entrega, prevalece o plano v2.

## Como executar

Ambiente: Flutter com Dart compatível com `^3.13.2` (versão local verificada: Flutter 3.47.2 / Dart 3.13.2), Android SDK e um emulador Android ou aparelho com depuração USB.

```bash
git clone https://github.com/OneStraider/Academia_Grazy-Grupo6.git
cd Academia_Grazy-Grupo6
flutter doctor
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo-android>
```

Substitua `<id-do-dispositivo-android>` pelo identificador retornado em `flutter devices`. No Windows, se o Flutter solicitar suporte a links simbólicos, habilite o Modo de Desenvolvedor nas configurações do sistema. Use o Dart incluído no Flutter para manter as versões alinhadas.

O alvo de validação do plano é Android. A presença das pastas de outras plataformas não significa que o banco SQLite já esteja configurado para elas.

## Estrutura e responsáveis

| Área | Responsável |
|---|---|
| Projeto, dependências, entrada do app e README | Arthur (AR) |
| Usuário, autenticação, navegação, telas da agenda e Home | Arthur (AR) |
| Banco, horários, regras de agendamento e testes dos services | Igor (IG) |
| Regras e services de treino, lista e execução do treino | Guilherme Weber (GW) |
| Avaliação, evolução e tela de montagem de treino | Guilherme Lermen (GL) |
| Tema, catálogo, componentes, detalhes do treino e perfil | Felipe (FE) |

```text
lib/
  main.dart
  theme/
  models/
  database/
  services/
  screens/
    login/
    home/
    exercicios/
    treinos/
    agendamentos/
    evolucao/
    perfil/
  widgets/
test/
  services/
```

Na **AR-T1**, os arquivos que faltavam no capítulo 3 foram criados com `TODO` indicando o dono. Esses arquivos são espaços reservados: suas funcionalidades serão implementadas nas tarefas de cada responsável. Os arquivos de testes dos services têm apenas um `main` vazio para serem carregados pelo executor; os testes ficam para o Igor na IG-T5.

O repositório já continha implementações com nomes anteriores, como `exercicios.dart`, `treino_exercicios.dart`, `treino_services.dart` e `home_shell.dart`. Elas continuam em uso. A adequação aos nomes e contratos do plano v2 cabe aos respectivos responsáveis; os novos arquivos ainda não substituem os antigos.

Dependências previstas: `sqflite`, `path`, `google_fonts`, `crypto` e `intl`. Para os testes de banco: `sqflite_common_ffi` em `dev_dependencies`. O `pubspec.lock` deve acompanhar as alterações das dependências.

## Login e dados de teste

O login do plano v2 depende das tarefas AR-T2 e AR-T3 e dos dados iniciais do banco do Igor (IG-T2). Ainda não há credenciais de login validadas nesta base. Os usuários e as instruções de acesso serão documentados quando essas tarefas estiverem integradas.

## Verificação

```bash
flutter analyze
flutter test
```

Além dessas verificações, a AR-T1 exige executar o app no emulador Android. Arquivos com `TODO` e testes vazios não comprovam a implementação dos requisitos futuros.

## Fluxo de trabalho do plano v2

- Uma branch por tarefa: `feat/<iniciais>-<tarefa>-<assunto>`, como `feat/ar-t1-projeto-repositorio`; correções usam `fix/`.
- Um Pull Request por tarefa, com o código no título, destinado à `main` e com uma aprovação.
- Commits em português com os prefixos `feat:`, `fix:` ou `test:`.
- Cada integrante implementa somente os arquivos e tarefas atribuídos a ele. Alterações em arquivos de outro dono devem ser combinadas com o responsável.

A proteção da `main` é configurada no GitHub e precisa ser conferida pelo responsável pelo repositório.
