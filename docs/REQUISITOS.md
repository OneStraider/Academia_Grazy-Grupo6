# Requisitos — Academia Grazy (Biopark)

Origem: *Documento para Levantamento de Requisitos, versão 01* — consolidado em
19/08/2026 a partir das entrevistas com a gestora da unidade Biopark.

**RF** = requisito funcional · **RNF** = requisito não funcional

---

## Objetivo geral

Sistema Integrado de Gestão de Treinos, Agendamento e Operação de Academia
(App Mobile & Web).

## Restrições e premissas

- **Foco prioritário no módulo de treinos.** A entrega inicial prioriza o
  ecossistema de treinos e acompanhamento físico; módulos financeiros complexos
  são secundários no escopo inicial.
- **Segregação de dados financeiros.** Alunos presenciais da unidade Biopark não
  devem visualizar painel financeiro completo no app de treino.
- **Conformidade com a LGPD.** Dados de saúde, histórico médico e fotos corporais
  exigem criptografia em repouso e termo de consentimento explícito.
- **Compatibilidade e acessibilidade.** Interface multiplataforma (iOS/Android)
  simplificada para alunos sem experiência prévia, além de painel administrativo
  responsivo/Web.
- **Modelo de negócio híbrido.** Suporte simultâneo a atendimento presencial por
  serviços avulsos e planos recorrentes para consultoria remota.

---

## Módulo 1 — Treinos  ·  REQ-01 a REQ-11

Frente prioritária da entrega inicial.

| Item | Requisito | Tipo |
|---|---|---|
| REQ-01 | Cadastro e manutenção de catálogo reutilizável de exercícios por grupo muscular. | RF |
| REQ-02 | Criação de modelos de treino padrão com variações por gênero e condições clínicas. | RF |
| REQ-03 | Montagem e edição de fichas de treino personalizadas por aluno. | RF |
| REQ-04 | Adição e remoção individual de exercícios em treinos já ativos. | RF |
| REQ-05 | Visualização do treino pelo aluno com instruções de execução e mídias explicativas. | RF |
| REQ-06 | Registro de execução pelo aluno (tempo gasto, cargas e conclusão de séries). | RF |
| REQ-07 | Canal de feedback bidirecional entre professor e aluno referente ao treino. | RF |
| REQ-08 | Rastreabilidade de autoria de montagem e alterações de treinos por professor. | RF |
| REQ-09 | Controle de validade e alertas de renovação/revisão periódica de treinos. | RF |
| REQ-10 | Disponibilização e contratação de linha de treinos para uso remoto/doméstico. | RF |
| REQ-11 | Módulo de Inteligência Artificial para geração e sugestão de treinos personalizados. | RF |

Branch sugerida para começar: `feature/REQ-01-catalogo-exercicios`

---

## Módulo 2 — Avaliação Física  ·  REQ-12 a REQ-18

Contém dados sensíveis de saúde — atenção redobrada à LGPD (REQ-33).

| Item | Requisito | Tipo |
|---|---|---|
| REQ-12 | Cadastro de medidas corporais (peso, altura, % gordura, massa magra, dobras e fotos). | RF |
| REQ-13 | Cálculo automatizado de IMC e divisão de composição corporal. | RF |
| REQ-14 | Parametrização de fórmulas e protocolos de avaliação física adotados pela academia. | RF |
| REQ-15 | Ficha de anamnese e saúde (medicações, restrições médicas, histórico de fraturas/lesões). | RF |
| REQ-16 | Registro de dados do médico responsável pelo acompanhamento do aluno. | RF |
| REQ-17 | Histórico evolutivo e comparativo de avaliações físicas e fotos de progresso. | RF |
| REQ-18 | Fluxo de cadastro diferenciado (simplificado para remotos vs. detalhado para presenciais). | RF |

Branch sugerida: `feature/REQ-12-medidas-corporais`

---

## Módulo 3 — Agendamento  ·  REQ-19 a REQ-22

| Item | Requisito | Tipo |
|---|---|---|
| REQ-19 | Agendamento in-app de aulas particulares (personal) e aulas coletivas. | RF |
| REQ-20 | Confirmação e controle de presença/check-in em aulas pelo aluno e professor. | RF |
| REQ-21 | Travas de antecedência mínima para agendamentos e cancelamentos de horários. | RF |
| REQ-22 | Limitação de vagas em turmas conforme capacidade máxima por modalidade. | RF |

Branch sugerida: `feature/REQ-19-agendamento-aulas`

---

## Módulo 4 — Financeiro  ·  REQ-23 a REQ-26

Secundário no escopo inicial. Alunos presenciais não visualizam painel financeiro
completo no app de treino.

| Item | Requisito | Tipo |
|---|---|---|
| REQ-23 | Registro financeiro de cobranças, mensalidades e contratação de serviços avulsos. | RF |
| REQ-24 | Disparo de alertas e notificações automáticas de vencimento e inadimplência. | RF |
| REQ-25 | Bloqueio automático de acesso às rotinas de treino em caso de inadimplência ativa. | RF |
| REQ-26 | Gateway de pagamento integrado para transações via cartão e PIX. | RF |

Branch sugerida: `feature/REQ-23-registro-cobrancas`

---

## Módulo 5 — Administrativo  ·  REQ-27 a REQ-31

| Item | Requisito | Tipo |
|---|---|---|
| REQ-27 | Dashboard administrativo com métricas de produtividade e volume de atendimento por professor. | RF |
| REQ-28 | Indicadores de balanceamento de carga e carteira de alunos por professor. | RF |
| REQ-29 | Gatilhos de reengajamento para alunos inativos com abertura de chamado manual. | RF |
| REQ-30 | Disparo de notificações push institucionais e ofertas comerciais customizadas. | RF |
| REQ-31 | Controle de permissões baseado em papéis (Aluno, Professor, Administrador). | RF |

Branch sugerida: `feature/REQ-27-dashboard-produtividade`

> REQ-31 é transversal: o controle de papéis afeta todos os módulos. Vale
> implementá-lo cedo, junto com o módulo de treinos.

---

## Requisitos não funcionais  ·  REQ-32 a REQ-38

Valem para o projeto inteiro, não para uma branch específica.

| Item | Requisito | Tipo |
|---|---|---|
| REQ-32 | Interface com usabilidade otimizada para onboarding rápido de alunos sem instrução prévia. | RNF |
| REQ-33 | Conformidade com as diretrizes da LGPD para dados sensíveis de saúde. | RNF |
| REQ-34 | Suporte multiplataforma (iOS e Android) e painel web administrativo responsivo. | RNF |
| REQ-35 | Aplicação visual da identidade de marca, paleta de cores e tipografia da academia. | RNF |
| REQ-36 | Arquitetura desacoplada com APIs REST para integração ou importação do MFIT e Cloudgin. | RNF |
| REQ-37 | Tempo de resposta para consultas de treinos e listas de agendamento ≤ 2 segundos. | RNF |
| REQ-38 | Disponibilidade da infraestrutura em nuvem de no mínimo 99,5%. | RNF |

---

## Papéis de usuário (REQ-31)

| Papel | Acesso |
|---|---|
| **Aluno** | Visualiza e executa o próprio treino, registra execução, envia feedback, agenda aulas, faz check-in, acompanha a própria evolução física. Não vê painel financeiro completo (presencial Biopark). |
| **Professor** | Monta e edita fichas de treino, aplica avaliações físicas, responde feedback, confirma presença, vê a própria carteira de alunos. |
| **Administrador** | Tudo acima, mais dashboard de produtividade, financeiro, notificações institucionais e gestão de permissões. |

---

## Rastreabilidade

Toda branch e todo Pull Request devem citar o requisito que atendem
(`Refs: REQ-XX`). Isso mantém o histórico do Git alinhado a este documento e
atende diretamente ao REQ-08, que exige rastreabilidade de autoria e alterações.

## Pendências do documento de origem

- Seção 1 (*Nome do sistema / funcionalidade*): em branco no documento — definir com a gestora.
- Seção 6 (*Imagens*): sem conteúdo — aguardando wireframes e a identidade visual da academia (REQ-35).
- Seção 7 (*Aprovação*): assinaturas da gestora e do líder técnico ainda pendentes.
