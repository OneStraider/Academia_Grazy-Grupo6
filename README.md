# Academia Grazy

Aplicativo Flutter para gestão local de treinos, exercícios, aulas, avaliações físicas e usuários da Academia Grazy. Os dados são persistidos em SQLite no Android e em SQLite/WASM no Chrome; não existe sincronização automática entre navegador, aparelhos ou instalações.

## Perfis e contas de demonstração

O banco local é inicializado com um administrador, dez professores, dez alunos, catálogo de exercícios e registros de demonstração. Todas as contas incluídas na carga inicial usam a senha `grazy123`.

| Perfil | E-mail | Senha |
|---|---|---|
| Administrador | `admin@academiagrazy.com` | `grazy123` |
| Professor | `professor@academiagrazy.com` | `grazy123` |
| Professora | `ana@academiagrazy.com` | `grazy123` |
| Aluno | `guilherme@academiagrazy.com` | `grazy123` |
| Aluna | `maria@academiagrazy.com` | `grazy123` |

Os outros professores usam os e-mails `bruno`, `camila`, `diego`, `fernanda`, `gustavo`, `helena`, `igor` e `julia` em `@academiagrazy.com`. Os outros alunos são `joao`, `larissa`, `pedro`, `beatriz`, `lucas`, `sofia`, `matheus` e `isabela`, também em `@academiagrazy.com`. Todos usam a mesma senha de demonstração.

Na primeira abertura com esta versão, uma migração adiciona as contas que faltam e grava, uma única vez, treinos com exercícios e execuções, avaliações físicas e aulas agendadas distribuídos por aproximadamente um mês. Os registros de avaliação e medidas corporais são fictícios para demonstração; não devem ser usados como orientação de saúde. A migração preserva os dados locais existentes e não repete a carga ao reiniciar o app.

## Regras de negócio

### Contas e autenticação

- O e-mail é normalizado para minúsculas e espaços externos são removidos. A senha é armazenada como hash.
- O cadastro público cria somente contas de aluno, exige nome com pelo menos três caracteres, e-mail válido e senha com pelo menos oito caracteres.
- Contas de professor são criadas pela administração. A conta ADMIN não é criada pelo formulário público.
- Contas bloqueadas não podem entrar. Um administrador pode bloquear ou reativar alunos e professores, mas não pode desativar a própria conta. O administrador não é listado como pessoa comum na gestão de usuários.
- A recuperação de senha por e-mail exige uma API configurada via `API_BASE_URL`; sem ela, o app informa que o serviço não está configurado. A base local não envia e-mails.

### Exercícios e treinos

- Professores consultam e mantêm o catálogo de exercícios e montam treinos associando exercícios, ordem, séries, repetições, carga, descanso e observações.
- O treino é atribuído a um aluno e recebe data de validade. Ao cadastrar um novo treino, o treino anterior daquele aluno que ainda esteja ATIVO passa a INATIVO.
- O aluno consulta os treinos vinculados à própria conta e pode executar exercícios um a um, registrar carga/repetições e enviar feedback.
- Um treino é considerado concluído quando todos os exercícios dele têm ao menos uma execução acompanhada de feedback. O histórico é mantido; treinos concluídos não podem ser editados. Treinos ATIVOS cuja validade passou são exibidos como vencidos.
- A tela administrativa mostra treinos e seu estado de conclusão por professor. Os gráficos contam registros persistidos, sem gerar métricas artificiais.

### Aulas e agendamentos

- Professores criam horários com nome, início, capacidade e mínimo de participantes. O início precisa estar pelo menos uma hora no futuro; capacidade e mínimo precisam ser positivos, e o mínimo não pode ultrapassar a capacidade.
- Alunos ativos podem reservar uma vaga se ainda houver capacidade e se não tiverem outra reserva ativa naquele horário. A reserva também deve ocorrer com pelo menos uma hora de antecedência.
- O aluno pode cancelar até duas horas antes do início. O check-in fica disponível nos 30 minutos que antecedem a aula, até o horário começar.
- Professor pode ver participantes, alterar horário/capacidade quando as reservas atuais couberem na capacidade nova e cancelar um horário; ao cancelar, reservas pendentes são marcadas como canceladas.

### Avaliação física e evolução

- Professor registra a avaliação de um aluno, incluindo peso, altura, percentual de gordura opcional, massa magra e observações/anamnese. O IMC é calculado a partir de peso e altura.
- O aluno consulta suas próprias avaliações e evolução. Professor seleciona o aluno para consultar ou registrar uma avaliação.
- A área administrativa pode consultar avaliações por período, filtrar abertas/concluídas, alterar o status ou excluir após confirmação.

### Administração

- O acesso administrativo é restrito a uma conta autenticada com perfil ADMIN; os services também validam esse perfil antes de executar operações administrativas.
- O painel apresenta treinos criados, avaliações realizadas e novos alunos no período, além de séries de treinos por professor, novos alunos e total acumulado de alunos. Os filtros disponíveis são semana, mês e ano; os gráficos podem ser exibidos em linhas ou barras. A série de treinos permite filtrar professor.
- A aba de usuários permite buscar por nome/e-mail, filtrar alunos/professores e cadastrar, editar, bloquear ou reativar contas. Mudanças de acesso pedem confirmação.
- A equipe permite abrir o perfil do professor e ver seus treinos em andamento e concluídos, com aluno e validade. Avaliações administrativas incluem aluno, professor, data e status.
- Os dados dos gráficos e listas vêm do banco local. Uma base recém-criada é preenchida pela carga demonstrativa descrita acima; uso posterior reflete as operações feitas pelos usuários.

## Como funciona cada tela

### Aluno

| Tela | O que o aluno faz |
|---|---|
| Home | Consulta resumo do treino ativo, próxima aula, avaliações e atalhos. |
| Treinos | Vê treinos atribuídos, validade, exercícios e detalhes; inicia ou retoma execução e registra feedback. |
| Agenda | Consulta horários e vagas, reserva, faz check-in dentro da janela permitida ou cancela dentro do prazo. |
| Evolução | Consulta medidas, IMC e avaliações registradas ao longo do tempo. |
| Perfil | Consulta e edita os dados de perfil disponíveis no app, preferências e saída da conta. |

### Professor

| Tela | O que o professor faz |
|---|---|
| Home | Vê alunos e treinos associados e as próximas aulas da equipe. |
| Exercícios | Busca por nome/grupo muscular e cadastra, edita ou remove exercícios. A imagem pode ser selecionada no dispositivo; o recorte avançado depende da plataforma. |
| Treinos | Busca alunos, cria treinos com exercícios, acompanha estados ativo/vencido/concluído e consulta execuções/feedbacks. |
| Agenda | Cria e gerencia aulas, capacidade, mínimo de participantes e reservas. |
| Perfil | Consulta e edita o próprio perfil e encerra a sessão. |

### Administrador

O painel tem quatro módulos: **Visão geral**, **Alunos e usuários**, **Equipe** e **Avaliações**. No desktop, usa navegação lateral; no mobile, navegação inferior. Toque nos itens ou deslize horizontalmente para mudar de módulo.

| Módulo | O que o administrador faz |
|---|---|
| Visão geral | Consulta cards de resumo, escolhe referência/período e explora gráficos de treinos por professor, novos alunos e total de alunos. |
| Alunos e usuários | Busca, filtra, cadastra/edita e controla acesso de alunos e professores. |
| Equipe | Busca professores e abre perfil com informações básicas, treinos em andamento e concluídos. |
| Avaliações | Consulta avaliações no período, filtra status, atualiza estado ou exclui com confirmação. |

## Executar no Chrome

### Pré-requisitos

- Flutter SDK instalado e `flutter doctor` sem problemas impeditivos.
- Google Chrome instalado.
- Execute os comandos dentro da pasta que contém `pubspec.yaml` (por exemplo, `Academia_Grazy-Grupo6`).

```powershell
flutter doctor
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8080
```

Se a porta estiver ocupada, encerre a execução anterior com `q` no terminal do Flutter ou use outra porta, por exemplo `--web-port 8082`. A porta faz parte da origem do navegador: mantenha a mesma porta para continuar usando o mesmo banco IndexedDB. Se a página mostrar uma versão antiga, pare o servidor antigo, inicie a partir da pasta do projeto atualizado e faça recarga forçada com `Ctrl+Shift+R`.

Para gerar os arquivos da versão web:

```powershell
flutter build web --release
```

O resultado fica em `build/web`. A versão web requer WebAssembly, workers e armazenamento local habilitados no navegador. Apagar os dados do site remove o banco local.

## Gerar APK para Android

Pré-requisitos: Flutter SDK e Android SDK instalados. Confira `flutter doctor` e conecte um aparelho com depuração USB ou inicie um emulador.

```powershell
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

Para gerar o APK release:

```powershell
flutter build apk --release
```

O arquivo será criado em `build/app/outputs/flutter-apk/app-release.apk`. Para instalar em um aparelho conectado, execute `flutter install` depois do build.

## Persistência e limitações conhecidas

- Android usa a implementação SQLite nativa existente (`sqflite`). Chrome usa SQLite compilado para WebAssembly com armazenamento local IndexedDB.
- Cada instalação/dispositivo/origem do navegador tem seu próprio banco. Não há hospedagem, sincronização entre aparelhos ou API central para treinos, alunos e avaliações.
- Seleção de imagem funciona no navegador; recorte avançado de imagem é limitado e fica disponível conforme suporte do plugin/plataforma. Os dados locais do site podem ser apagados pelo navegador.
- Recuperação de senha e cadastro integrado a serviço remoto só funcionam se `API_BASE_URL` apontar para uma API compatível e acessível.

## Verificações

```powershell
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```
