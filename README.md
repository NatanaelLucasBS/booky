# Booky — Biblioteca Pessoal e Rastreamento de Leitura

O **Booky** é um aplicativo desenvolvido em **Flutter** voltado para leitores organizarem seu acervo de livros físicos e digitais, acompanharem o progresso e as estatísticas de leitura, registrarem anotações e citações (com leitura de páginas via câmera) e controlarem empréstimos de livros para amigos.

---

## Funcionalidades do Aplicativo

### 1. Catalogação de Livros (Scanner ISBN + API Open Library)
- **Leitura de Código de Barras:** Scanner integrado à câmera (`mobile_scanner`) para leitura rápida do código ISBN diretamente da contracapa do livro físico.
- **Busca Automática de Dados:** Integração com a **Open Library API**, preenchendo automaticamente capa, título, autor, editora, ano de publicação, gênero, número de páginas e sinopse (com suporte a ISBN-10 e ISBN-13).
- **Cadastro e Edição Manual:** Formulário completo para cadastrar livros manualmente ou revisar e complementar as informações obtidas pela busca.

### 2. Organização por Estantes, Status e Tags
- **Classificação por Status:** Organização dos livros em quatro categorias: *Quero Ler*, *Lendo*, *Lido* e *Abandonado*.
- **Formato e Avaliação:** Identificação de livros *Físicos* ou *Digitais (E-book)* e avaliação pessoal de 1 a 5 estrelas.
- **Estantes Temáticas e Tags:** Criação, edição e exclusão de estantes personalizadas (ex.: *Favoritos*, *Ficção*, *Faculdade*) e adição de tags livres para facilitar a organização do acervo.

### 3. Rastreador de Progresso e Sessões de Leitura
- **Cronômetro de Leitura:** Contador de tempo com opções de iniciar, pausar, retomar e concluir sessão.
- **Atualização de Progresso:** Controle da página atual pelos botões `-` e `+`, barra deslizante (`Slider`) ou digitação direta da **página atual** ou **porcentagem concluída (`%`)**.
- **Ritmo e Estimativa:** Cálculo automático da velocidade média de leitura (páginas por hora) e estimativa de tempo restante para terminar o livro.
- **Histórico Diário:** Registro das sessões agrupadas por data e atualização automática do status do livro para *Lido* ao atingir o total de páginas.

### 4. Diário de Leitura com OCR (Anotações, Citações e Resenha)
- **Três Categorias de Registro:** Aba de *Anotações* gerais, aba de *Citações* favoritas (com indicação de capítulo e página) e aba de *Resenha* do livro.
- **Extração de Texto via Câmera (OCR):** Suporte a reconhecimento ótico de caracteres local com **Google ML Kit** (`google_mlkit_text_recognition`), permitindo fotografar ou selecionar a foto de uma página física para extrair o trecho de texto automaticamente.

### 5. Controle de Empréstimos
- **Registro de Empréstimos:** Cadastro do nome do amigo, telefone/contato, data do empréstimo e data prevista de devolução.
- **Alertas de Atraso:** Identificação visual automática de empréstimos vencidos na estante, aviso no painel inicial e agendamento de notificação local no aparelho para lembrar a data de devolução.
- **Devolução e Histórico:** Marcação de devolução com um toque e manutenção do histórico de empréstimos anteriores na ficha do livro.

### 6. Busca Avançada, Estatísticas e Metas
- **Filtros Combinados:** Busca por título ou autor combinada com filtros avançados por autor, gênero, ano de publicação, status, avaliação mínima por estrelas, estante temática e tag.
- **Gráficos e Meta Anual:** Painel inicial com acompanhamento da meta anual de leitura, lembrete diário configurável e gráfico mensal (`fl_chart`) alternável entre **Páginas Lidas** e **Livros Lidos** nos últimos meses.

### 7. Backup e Exportação (PDF, CSV e JSON)
- **Exportação em PDF e CSV:** Geração e compartilhamento do **Catálogo Completo** ou da **Lista de Desejos (Quero Ler)** em documento PDF formatado ou planilha CSV compatível com Excel e Google Planilhas.
- **Backup e Restauração:** Exportação de todas as informações do aplicativo em um arquivo JSON para armazenamento em nuvem ou transferência entre dispositivos, com opção de restauração completa no próprio aplicativo.

---

## Arquitetura do Projeto (MVVM)

O código está estruturado seguindo o padrão **MVVM (Model–View–ViewModel)** dividido em camadas para manter a interface separada das regras de negócio e do acesso a dados:

```text
lib/
├── main.dart                     # Inicialização do app, tema, rotas e providers
├── core/
│   ├── constants/                # Constantes gerais da aplicação
│   ├── di/                       # Configuração e injeção de dependências (Provider)
│   ├── routes/                   # Rotas nomeadas da aplicação
│   └── theme/                    # Paleta de cores e temas Claro / Escuro
├── domain/
│   ├── models/                   # Modelos de dados (Book, Shelf, ReadingSession, Note, Loan, AppSettings)
│   ├── repositories/             # Contratos (interfaces) dos repositórios
│   └── use_cases/                # Casos de uso com regras de negócio da aplicação
├── data/
│   ├── repositories/             # Implementação dos repositórios com Streams reativas
│   └── services/                 # Serviços de armazenamento JSON, API Open Library, OCR, notificações, PDF/CSV e backup
└── features/
    ├── home/                     # Tela inicial (Dashboard), gráficos e HomeViewModel
    ├── library/                  # Biblioteca, cadastro/scanner de livros, filtros e ViewModels
    ├── book_details/             # Detalhes do livro, diário com OCR, empréstimos e BookDetailsViewModel
    └── tracker/                  # Rastreador de leitura, cronômetro e TrackerViewModel
```

- **Model (`domain/models`, `data/repositories` e `data/services`):** Representa as estruturas de dados do domínio, a persistência local em JSON e a comunicação com serviços externos (Open Library API, câmera/OCR, notificações e geração de arquivos).
- **View (`features/*/presentation/screens` e `widgets`):** Responsável apenas pela exibição visual das telas e captura das interações do usuário.
- **ViewModel (`features/*/presentation/viewmodels`):** Gerencia o estado de cada tela usando `ChangeNotifier`, processa validações e comunica-se com os repositórios e casos de uso, notificando a `View` automaticamente via `context.watch` e `notifyListeners()`.

---

## Como Executar o Projeto

### Pré-requisitos
- Flutter SDK instalado
- Dispositivo Android conectado via USB ou emulador configurado

### Comandos

```bash
# 1. Instalar as dependências do projeto
flutter pub get

# 2. Executar a análise estática do código
flutter analyze

# 3. Executar os testes automatizados
flutter test

# 4. Rodar o aplicativo no dispositivo conectado
flutter run

# 5. Gerar o APK de distribuição (Release)
flutter build apk --release
```
