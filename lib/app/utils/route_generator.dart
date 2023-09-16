import 'package:flutter/material.dart';
import 'package:uber_clone/app/pages/Auth_Email_Registration/auth_email_registration_page.dart';
import 'package:uber_clone/app/pages/Auth_Email_Sign_In/auth_email_sign_in_page.dart';
import 'package:uber_clone/app/pages/Auth/auth_page.dart';
import 'package:uber_clone/app/pages/Panel_Driver/panel_driver_page.dart';
import 'package:uber_clone/app/pages/Painel_Passenger/panel_passenger_page.dart';
import 'package:uber_clone/app/pages/Ride/ride_page.dart';
import 'package:uber_clone/app/pages/Splash/splash_page.dart';

import '../../data/models/screen_arguments.dart';

class RouteGenerator {
  static const String rSplash = "/";
  static const String rLogin = "/login";
  static const String rLoginEmail = "/login_email";
  static const String rCadastro = "/cadastro";
  static const String rPainelPassageiro = "/painel_passageiro";
  static const String rPainelMotorista = "/painel_motorista";
  static const String rRide = "/corrida";

  static Route<dynamic>? generatorRoute(RouteSettings settings) {
    ScreenArguments? args = settings.arguments as ScreenArguments?;

    switch (settings.name) {
      case rSplash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case rLogin:
        return MaterialPageRoute(builder: (_) => const AuthPage());
      case rLoginEmail:
        return MaterialPageRoute(builder: (_) => const AuthEmailSignInPage());
      case rCadastro:
        return MaterialPageRoute(
            builder: (_) => const AuthEmailRegistrationPage());
      case rPainelPassageiro:
        return MaterialPageRoute(builder: (_) => const PanelPassengerPage());
      case rPainelMotorista:
        return MaterialPageRoute(builder: (_) => const PanelDriverPage());
      case rRide:
        return MaterialPageRoute(builder: (_) => RidePage(args));
      default:
        return _erroRota();
    }
  }

  static Route<dynamic>? _erroRota() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Tela não encontrada!"),
        ),
        body: const Center(
          child: Text("Tela não encontrada"),
        ),
      );
    });
  }
}
