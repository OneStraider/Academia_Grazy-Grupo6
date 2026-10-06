# Academia Grazy  — Grupo 6

Sistema Integrado de Gestão de Treinos, Agendamento e Operação de Academia
(aplicativo mobile + painel web administrativo).

Projeto acadêmico — ADS 6 · Unidade Biopark.

---

## Objetivo

Digitalizar e otimizar a gestão operacional e de treinos da academia, oferecendo
aos alunos uma experiência autônoma e personalizada para visualização de treinos,
agendamento de aulas e contratações; disponibilizar ferramentas assistidas por IA
para montagem rápida de treinos pelos professores; possibilitar a venda de treinos
remotos; e fornecer ao administrador relatórios de produtividade da equipe e
controle financeiro.

## Stack

| Camada | Tecnologia |
|---|---|
| Aplicativo mobile (iOS/Android) | Flutter + Dart |
| Painel administrativo | Flutter Web (responsivo) |
| Integração | APIs REST (arquitetura desacoplada — REQ-36) |
| Controle de versão | Git + GitHub, fluxo GitFlow simplificado |

## Módulos

1. **Treinos** — catálogo de exercícios, fichas personalizadas, execução e feedback (REQ-01 a REQ-11)
2. **Avaliação Física** — medidas corporais, IMC, anamnese e histórico evolutivo (REQ-12 a REQ-18)
3. **Agendamento** — aulas particulares e coletivas, check-in e controle de vagas (REQ-19 a REQ-22)
4. **Financeiro** — cobranças, inadimplência e gateway de pagamento (REQ-23 a REQ-26)
5. **Administrativo** — dashboard de produtividade, reengajamento, notificações e permissões (REQ-27 a REQ-31)

Os requisitos completos estão em [`docs/REQUISITOS.md`](docs/REQUISITOS.md).

> **Prioridade de entrega:** o módulo de **Treinos** vem primeiro. Módulos
> financeiros complexos são secundários no escopo inicial.

## Estrutura de branches

| Branch | Papel |
|---|---|
| `main` | Código estável, apresentável a qualquer momento. Só recebe merge via Pull Request. |
| `develop` | Integração do time. Base de toda branch de trabalho. |
| `feature/*` | Uma funcionalidade ou requisito por branch. Sai de `develop`, volta para `develop`. |
| `hotfix/*` | Correção urgente em `main`. Volta para `main` **e** para `develop`. |

O fluxo completo, com comandos e regras, está em [`docs/GITFLOW.md`](docs/GITFLOW.md).
O passo a passo do dia a dia está em [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Como começar

```bash
git clone https://github.com/OneStraider/Academia_Grazy-Grupo6.git
cd Academia_Grazy-Grupo6
git checkout develop
```

Quando o projeto Flutter for criado nesta base:

```bash
flutter pub get
flutter run
```

## Requisitos de ambiente

- Flutter SDK (canal stable)
- Dart SDK (vem junto com o Flutter)
- Android Studio ou VS Code com as extensões Flutter e Dart
- Git

Confira a instalação com:

```bash
flutter doctor
```

## Equipe

Grupo 6 — ADS 6.

| Integrante | Função | GitHub |
|---|---|---|
| Guilherme Cauã | Líder técnico | [@OneStraider](https://github.com/OneStraider) |
| Arthur Paludo | Líder técnico | [@arthurberwanger](https://github.com/arthurberwanger) |
| Igor Daniel | Líder técnico | [@dev-igordaniel](https://github.com/dev-igordaniel) |
| Guilherme Weber| Líder técnico | [@Guilhermeweber25](https://github.com/Guilhermeweber25) |
| Felipe Augusto | Líder técnico | [@fellps1911](https://github.com/fellps1911) |

## Aviso sobre dados sensíveis

O sistema trata dados de saúde (anamnese, histórico médico, fotos corporais) e
está sujeito à LGPD. **Nunca** versione neste repositório: chaves de API,
credenciais do gateway de pagamento, arquivos `.env`, dumps de banco ou qualquer
dado real de aluno. Use `.env.example` para documentar as variáveis necessárias.
