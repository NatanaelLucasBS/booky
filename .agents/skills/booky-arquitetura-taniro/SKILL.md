---
name: booky-arquitetura-taniro
description: >-
  Regras estritas da Arquitetura Recomendada pelo Prof. Taniro (Aula 24 - MVVM,
  UDF, SSOT, Layered Architecture e ConfigureProviders). Ative sempre que for
  criar ou editar Views, ViewModels, UseCases, Repositories, Services ou a
  injecao de dependencias no projeto BOOKY.
---

# Skill: Arquitetura Recomendada Flutter — Prof. Taniro (`Aula_24`)

Esta skill garante que todo código escrito para o **BOOKY** obedeça 100% aos slides de `Aula_24_-_Arqutietura_Recomendada.pdf` e ao template `todo_app_arch`, sem alucinar padrões externos.

## 1. As 3 Camadas e Seus Papéis (Slides 5 a 29)

1. **UI Layer (`lib/features/<feature>/presentation/`):**
   - **View (`screens/` e `widgets/`):** Descreve como apresentar os dados. Recebe dados prontos do `ViewModel`.
     - *Permitido na View (Slide 16):* condicionais simples (`if`) para mostrar/ocultar widgets, animações, layout (`MediaQuery`/`LayoutBuilder`) e navegação simples.
     - *Proibido na View:* cálculos de negócio, filtros de lista, chamadas `http`, acesso a `Service` ou `Repository` direto.
   - **ViewModel (`viewmodels/<feature>_viewmodel.dart`):**
     - Estende `ChangeNotifier`.
     - Relação **1:1** com a View (Slide 15): cada tela principal possui seu próprio `ViewModel`.
     - Converte dados dos `Repositories` em *UI State*, mantém flags (`isLoading`, `errorMessage`, filtros selecionados) e expõe *commands* (métodos assíncronos que a View aciona em botões/formulários — Slide 18).
2. **Domain / Logic Layer (`lib/domain/`):**
   - `models/`: classes de domínio imutáveis (`copyWith`, `toJson`, `fromJson`, getters puros). Não importam pacotes de UI nem de banco.
   - `repositories/`: interfaces abstratas (`abstract interface class`) definindo os contratos SSOT.
   - `use_cases/`: classes que encapsulam regras de negócio que **combinam múltiplos repositórios** (Slides 7, 23, 27).
3. **Data Layer (`lib/data/`):**
   - **Repositories (`lib/data/repositories/`):**
     - São a **Fonte Única de Verdade (SSOT)** para um único tipo de dado (Slides 4, 8, 22).
     - Único lugar autorizado a mutar aquele dado.
     - Expõem `Stream<List<T>>` / `Future<T>` com modelos de domínio.
     - **LEI INVIOLÁVEL (Slide 23):** *Um Repository NUNCA pode depender de outro Repository.* Se precisar combinar dados de 2 repositórios, faça no `UseCase` ou no `ViewModel`.
   - **Services (`lib/data/services/`):**
     - Camada mais baixa, **100% stateless** (Slide 8 e 25).
     - Isolam APIs externas (`http`), plugins nativos (`mobile_scanner`, `image_picker`, `google_mlkit_text_recognition`, `flutter_local_notifications`, `pdf`, `csv`, `share_plus`) e armazenamento (`StorageService`, `BackupSyncService`).
     - Consumidos apenas por `Repositories` (ou `UseCases` no caso de serviços de ação como notificação/exportação).

## 2. Padrão de Injeção de Dependências (`ConfigureProviders`)

Siga o padrão do commit inicial `92e5710` (`todo_app_arch`) em `lib/core/di/configure_providers.dart`:

```dart
class ConfigureProviders {
  final List<SingleChildWidget> providers;
  ConfigureProviders({required this.providers});

  static Future<ConfigureProviders> createDependencyTree() async {
    // 1. Instanciar Services (stateless)
    // 2. Instanciar Repositories (injetando Services)
    // 3. Instanciar UseCases (injetando Repositories/Services)
    // 4. Instanciar ViewModels globais (injetando Repositories/UseCases)
    return ConfigureProviders(providers: [
      // Provider<...>.value(value: ...),
      // ChangeNotifierProvider<...>.value(value: ...),
    ]);
  }
}
```

Para telas de rota com parâmetros (`AddBookScreen`, `BookDetailsScreen`, `ReadingTrackerScreen`), instancie o `ChangeNotifierProvider` específico da tela dentro de `AppRoutes.onGenerateRoute`, lendo os `Repositories`/`UseCases` via `context.read<T>()` para que o `ViewModel` seja descartado (`dispose`) ao fechar a tela.

## 3. Checklist de Verificação Antes de Entregar Código

- [ ] Alguma `Screen` ou `Widget` importou algo de `lib/data/`? Se sim, **remova imediatamente**.
- [ ] Algum `Repository` recebeu outro `Repository` no construtor? Se sim, **mova a coordenação para um `UseCase`**.
- [ ] Algum `Service` guardou estado mutável de domínio? Se sim, **mova o estado para o `Repository` (SSOT) ou `ViewModel` (UI State)**.
- [ ] Alguma dependência de Firebase foi adicionada? Se sim, **remova imediatamente** (o projeto abstrai persistência via `StorageService`).
- [ ] Rode `flutter analyze` para validar zero erros de lint/tipagem.
