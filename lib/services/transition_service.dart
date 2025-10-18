import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransitionService {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Duration _fastDuration = Duration(milliseconds: 200);

  // Slide transitions
  static Widget slideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    {Offset begin = const Offset(1.0, 0.0)}
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  // Fade transition
  static Widget fadeTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }

  // Scale transition
  static Widget scaleTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Custom page route with transition
  static PageRouteBuilder createRoute(
    Widget page, {
    Duration duration = _defaultDuration,
    RouteTransitionsBuilder? transition,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: transition ?? (context, animation, secondaryAnimation, child) => 
        slideTransition(animation, secondaryAnimation, child),
    );
  }

  // Navigation with custom transitions
  static Future<T?> navigateWithTransition<T>(
    Widget page, {
    bool replace = false,
    bool clearStack = false,
    Duration duration = _defaultDuration,
    RouteTransitionsBuilder? transition,
  }) async {
    final route = createRoute(page, duration: duration, transition: transition);
    
    if (clearStack) {
      return await Get.offAll(() => page);
    } else if (replace) {
      return await Get.off(() => page);
    } else {
      return await Navigator.of(Get.context!).push<T>(route as Route<T>);
    }
  }

  // Predefined transitions
  static Future<T?> slideLeft<T>(Widget page, {bool replace = false}) {
    return navigateWithTransition<T>(
      page,
      replace: replace,
      transition: (context, animation, secondaryAnimation, child) => slideTransition(
        animation,
        secondaryAnimation,
        child,
        begin: const Offset(-1.0, 0.0),
      ),
    );
  }

  static Future<T?> slideRight<T>(Widget page, {bool replace = false}) {
    return navigateWithTransition<T>(
      page,
      replace: replace,
      transition: (context, animation, secondaryAnimation, child) => slideTransition(
        animation,
        secondaryAnimation,
        child,
        begin: const Offset(1.0, 0.0),
      ),
    );
  }

  static Future<T?> slideUp<T>(Widget page, {bool replace = false}) {
    return navigateWithTransition<T>(
      page,
      replace: replace,
      transition: (context, animation, secondaryAnimation, child) => slideTransition(
        animation,
        secondaryAnimation,
        child,
        begin: const Offset(0.0, 1.0),
      ),
    );
  }

  static Future<T?> fade<T>(Widget page, {bool replace = false}) {
    return navigateWithTransition<T>(
      page,
      replace: replace,
      transition: (context, animation, secondaryAnimation, child) => fadeTransition(
        animation,
        secondaryAnimation,
        child,
      ),
      duration: _fastDuration,
    );
  }

  static Future<T?> scale<T>(Widget page, {bool replace = false}) {
    return navigateWithTransition<T>(
      page,
      replace: replace,
      transition: (context, animation, secondaryAnimation, child) => scaleTransition(
        animation,
        secondaryAnimation,
        child,
      ),
      duration: _defaultDuration,
    );
  }
}