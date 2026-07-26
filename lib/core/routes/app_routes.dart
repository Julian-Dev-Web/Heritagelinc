/// Route name constants. Reference these everywhere instead of raw strings,
/// e.g. Navigator.pushNamed(context, AppRoutes.login) instead of '/login'.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}