import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/route_generator.dart';
import '../../app/widgets/show_snackbar.dart';
import '../../data/models/usuario.dart';

class Authentication {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore db = FirebaseFirestore.instance;

  static checkUser(BuildContext context) async {
    User? usuarioLogado = auth.currentUser;
    try {
      if (usuarioLogado != null) {
        if (kDebugMode) {
          print("Usuario Logado!!!");
        }
        if (usuarioLogado.email == null) {
          //showSnackbar(context, "Confirme o seu e-mail antes de continuar.");
          await auth.signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
              context, RouteGenerator.rLogin, (route) => false);
        } else {
          redirecionarPainelPorTipoUsuario(context, usuarioLogado.uid);
        }
      } else {
        if (kDebugMode) {
          print("Usuario Não Logado!!!");
        }
        Navigator.pushNamedAndRemoveUntil(
            context, RouteGenerator.rLogin, (route) => false);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao Logar Usuario: ${e.toString()}");
      }
      await signOut(context);
    }
  }

  static Future<void> signOut(BuildContext context) async {
    await auth.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, RouteGenerator.rSplash, (route) => false);
  }

  static Future createUser(BuildContext context, Usuario usuario) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: "${usuario.email}",
        password: "${usuario.senha}",
      );
      if (auth.currentUser != null) {
        usuario.id = auth.currentUser?.uid;
        db.collection("usuarios").doc(usuario.id).set(usuario.toMap());
        if (!context.mounted) return;
        redirecionarPainelPorTipoUsuario(context, "${usuario.id}");
        showSnackbar(context, "Conta de usuário ${usuario.tipoUsuario}");
        if (kDebugMode) {
          print("Conta de usuário ${usuario.tipoUsuario}");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        if (kDebugMode) {
          print('A senha fornecida é muito fraca.');
        }
        if (!context.mounted) return;
        showSnackbar(context, 'A senha fornecida é muito fraca.');
      } else if (e.code == 'email-already-in-use') {
        if (kDebugMode) {
          print('A conta já existe para esse e-mail.');
        }
        if (!context.mounted) return;
        showSnackbar(context, 'A conta já existe para esse e-mail.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!context.mounted) return;
      showSnackbar(context, 'Erro: $e');
    }
    return null;
  }

  static redirecionarPainelPorTipoUsuario(
      BuildContext context, String id) async {
    DocumentSnapshot snapshot = await db.collection("usuarios").doc(id).get();

    Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
    String tipoUsuario = dados["tipoUsuario"];

    if (kDebugMode) {
      print("Tipo de Usuario: $tipoUsuario");
    }
    switch (tipoUsuario) {
      case "motorista":
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, RouteGenerator.rPainelMotorista, (route) => false);
      case "passageiro":
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, RouteGenerator.rPainelPassageiro, (route) => false);
    }
  }

  static Future<String?> signIn(BuildContext context, Usuario usuario) async {
    try {
      await auth.signInWithEmailAndPassword(
          email: "${usuario.email}", password: "${usuario.senha}");
      if (auth.currentUser != null) {
        if (kDebugMode) {
          print("User Logado!!!");
        }

        return "Acessado o usuário";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if (kDebugMode) {
          print('Nenhum usuário encontrado para esse e-mail.');
        }
        if (context.mounted)
          showSnackbar(context, 'Nenhum usuário encontrado para esse e-mail.');
      } else if (e.code == 'wrong-password') {
        if (kDebugMode) {
          print('Senha errada fornecida para esse usuário.');
        }
        if (context.mounted)
          showSnackbar(context, 'Senha errada fornecida para esse usuário.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (context.mounted) showSnackbar(context, 'Erro: $e');
    }
    return null;
  }
}
