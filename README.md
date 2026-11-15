# BOOKY — Biblioteca Pessoal & Rastreador de Leitura

> **Disciplina:** Programação para Dispositivos Móveis (2026.2 — UFRN)  
> **Professor:** Taniro Chacon Rodrigues  
> **Tema:** 6. App de Biblioteca Pessoal e Rastreamento de Leitura  
> **Equipe:** Natanael & Cleiton

---

## Sobre o Projeto

O **BOOKY** é um aplicativo Flutter voltado para leitores organizarem seu acervo físico e digital, acompanharem metas e estatísticas de leitura, registrarem citações/resenhas (com suporte a OCR) e controlarem empréstimos de livros para amigos.

### Requisitos Funcionais (Tema 6)

1. **Catalogação por ISBN (Scanner + API):** Cadastro manual ou leitura do código de barras ISBN pela câmera (`mobile_scanner`), buscando automaticamente capa, título, autor, sinopse, editora e número de páginas via integração com a API do **Google Books** ou **Open Library**.
2. **Organização por Estantes e Status:** Classificação por status (*Quero Ler, Lendo, Lido, Abandonado*), formato (*Físico* ou *Digital*), avaliação pessoal (1 a 5 estrelas), tags customizadas e estantes temáticas.
3. **Rastreador de Progresso e Sessões:** Cronômetro de leitura e atualização da página atual ou porcentagem concluída, gerando histórico diário de páginas lidas e estimativa de tempo para terminar o livro.
4. **Diário de Citações e Resenhas:** Registro de anotações, resenhas e trechos favoritos de cada livro, com suporte a **OCR via câmera** (`google_mlkit_text_recognition`) para extrair texto diretamente da página física.
5. **Controle de Empréstimos:** Registro de livros emprestados (nome do amigo, contato, data do empréstimo e data prevista de devolução) com alerta visual e notificação local de atraso.
6. **Busca Avançada e Estatísticas:** Filtros combinados por autor, gênero, ano, status, estante, tag ou avaliação, além de gráficos (`fl_chart`) de livros/páginas lidas por mês e meta anual de leitura.
7. **Backup e Exportação:** Backup/sincronização de dados e exportação do catálogo completo ou lista de desejos em **PDF** e **CSV**.

---

## Arquitetura (`Aula_24_-_Arqutietura_Recomendada.pdf`)

O projeto segue a arquitetura recomendada pelo time Flutter e apresentada em aula:
- **Padrão MVVM (Model-View-ViewModel)** com `Provider` e injeção de dependências centralizada em `ConfigureProviders`.
- **Arquitetura em Camadas:**
  - **UI Layer (`lib/features/*/presentation/`):** `Views` (Screens/Widgets puramente visuais) e `ViewModels` (`ChangeNotifier` na relação 1:1 com cada tela).
  - **Domain / Logic Layer (`lib/domain/`):** Modelos de domínio imutáveis (`models/`), contratos abstratos (`repositories/`) e `use_cases/` para orquestrar múltiplos repositórios sem acoplá-los.
  - **Data Layer (`lib/data/`):** `Repositories` atuando como **Fonte Única de Verdade (SSOT)** reativa (`Stream`) e `Services` *stateless* isolando fontes externas/nativas (APIs REST, OCR, notificações, exportação e persistência abstraída).
- **Fluxo Unidirecional de Dados (UDF):** O estado flui dos `Repositories` para a `UI`, e eventos do usuário fluem da `UI` (via commands dos `ViewModels`) para a camada de dados.

---

## Documentação de Desenvolvimento

- **[`PLANO_DESENVOLVIMENTO.md`](./PLANO_DESENVOLVIMENTO.md):** Documento mestre de arquitetura, regras de negócio do Tema 6, contratos de dados e roadmap.
- **[`TASKS_NATANAEL.md`](./TASKS_NATANAEL.md):** Backlog e issues do Natanael.
- **[`TASKS_CLEITON.md`](./TASKS_CLEITON.md):** Backlog e issues do Cleiton.

---

## Como Executar e Testar

```bash
# 1. Instalar dependências
flutter pub get

# 2. Analisar código (lint e tipagem)
flutter analyze

# 3. Executar suíte de testes unitários e de widget
flutter test

# 4. Executar no dispositivo ou emulador Android
flutter run

# 5. Gerar APK de Release
flutter build apk --release
```
