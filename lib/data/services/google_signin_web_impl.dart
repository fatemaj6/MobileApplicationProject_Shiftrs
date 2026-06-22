import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

/// The real "Sign in with Google" button rendered by Google's own JS SDK.
/// Must be shown for real — GIS only allows sign-in via a genuine click
/// on its own button, not via an arbitrary onPressed handler.
Widget buildWebSignInButton(GoogleSignIn googleSignIn) {
  final plugin = GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
  return plugin.renderButton();
}