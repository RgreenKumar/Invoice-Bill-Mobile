import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// BUGFIX: this app navigates almost everywhere with `context.go(...)`
/// (sidebar, header, buttons), which replaces the current route rather
/// than pushing on top of it. That means `context.pop()` frequently has
/// nothing meaningful to pop back to.
///
/// An earlier version of this helper tried `context.canPop()` first and
/// only fell back to `context.go()` when that was false - but
/// `canPop()`/`pop()` proved unreliable inside this app's `ShellRoute`
/// navigator structure (it can report `true` and pop to a blank/empty
/// route within the shell's own nested Navigator, which is exactly the
/// "screen goes blank after saving" bug that was reported). To guarantee
/// correctness, this now always navigates with `context.go(fallback)`
/// and never calls `pop()` for primary navigation.
void safeBack(BuildContext context, {String fallback = '/dashboard/viewitem'}) {
  context.go(fallback);
}
