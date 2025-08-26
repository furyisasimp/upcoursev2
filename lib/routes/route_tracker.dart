import 'package:flutter/widgets.dart';

class RouteTracker extends RouteObserver<PageRoute<dynamic>> {
  static final RouteTracker instance = RouteTracker();

  // simple stack of named routes
  final List<String> _stack = [];

  // routes you NEVER want to navigate back to (e.g., login)
  static const Set<String> ignored = {'/login', '/signin', '/auth'};

  String? get lastRouteName {
    if (_stack.length < 2) return null;
    final candidate = _stack[_stack.length - 2];
    return ignored.contains(candidate) ? null : candidate;
  }

  @override
  void didPush(Route route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && route.settings.name != null) {
      _stack.add(route.settings.name!);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && route.settings.name != null) {
      _stack.remove(route.settings.name);
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is PageRoute && oldRoute.settings.name != null) {
      _stack.remove(oldRoute.settings.name);
    }
    if (newRoute is PageRoute && newRoute.settings.name != null) {
      _stack.add(newRoute.settings.name!);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
