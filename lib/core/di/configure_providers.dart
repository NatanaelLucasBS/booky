import 'package:provider/single_child_widget.dart';

/// Árvore de Injeção de Dependências no padrão do Prof. Taniro (`todo_app_arch`).
///
/// TODO(Natanael): Registrar Services -> Repositories -> UseCases -> ViewModels
/// nas Issues ISSUE-N05, ISSUE-N07 e ISSUE-N09.
class ConfigureProviders {
  final List<SingleChildWidget> providers;

  ConfigureProviders({required this.providers});

  static Future<ConfigureProviders> createDependencyTree() async {
    return ConfigureProviders(providers: const []);
  }
}
