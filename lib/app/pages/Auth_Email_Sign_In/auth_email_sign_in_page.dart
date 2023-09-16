import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/colors.dart';
import 'package:uber_clone/app/utils/route_generator.dart';
import '../../../data/models/usuario.dart';
import '../../../domain/usecases/authentication.dart';
import '../../utils/paths.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/show_snackbar.dart';

class AuthEmailSignInPage extends StatefulWidget {
  const AuthEmailSignInPage({Key? key}) : super(key: key);

  @override
  State<AuthEmailSignInPage> createState() => _AuthEmailSignInPageState();
}

class _AuthEmailSignInPageState extends State<AuthEmailSignInPage> {
  TextEditingController controllerEmail =
      TextEditingController(text: "adam@gmail.com");
  TextEditingController controllerSenha =
      TextEditingController(text: "123456789");

  final _formKey = GlobalKey<FormState>();

  bool vazio = true;
  bool obscureText = true;
  bool loading = false;
  Widget visibility = const Icon(Icons.visibility_off);
  _obscureText() {
    if (!vazio) {
      if (obscureText == true) {
        setState(() {
          visibility = const Icon(Icons.visibility);
        });
      } else if (obscureText == false) {
        setState(() {
          visibility = const Icon(Icons.visibility_off);
        });
      }
      setState(() {
        obscureText = !obscureText;
      });
    } else {
      if (kDebugMode) {
        print("controllerSenha vazio");
      }
    }
  }

  _onChanged(String controller) {
    if (controller.isEmpty) {
      setState(() {
        vazio = true;
      });
    } else {
      setState(() {
        vazio = false;
      });
    }
  }

  signIn() async {
    if (_formKey.currentState!.validate()) {
      if (loading == false) {
        setState(() {
          loading == true;
        });

        Usuario usuario = Usuario.toNull();
        usuario.email = controllerEmail.text;
        usuario.senha = controllerSenha.text;

        String? message = await Authentication.signIn(context, usuario);

        if (message != null) {
          if (kDebugMode) {
            print(message);
          }
          setState(() {
            loading = false;
          });
          if (!context.mounted) return;
          showSnackbar(context, message);
          Authentication.checkUser(context);
        } else {
          setState(() {
            loading = false;
          });
          if (!context.mounted) return;
          Authentication.checkUser(context);
        }

        setState(() {
          loading = false;
        });
      } else {
        if (kDebugMode) {
          print("Processo já em execução");
        }
      }
    } else {
      if (kDebugMode) {
        print("Nâo validado");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: loading
            ? CircularProgressIndicator(
                backgroundColor: darkBlueGray,
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ///Image
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: Image.asset(
                          ImagesPaths.logo,
                          width: 150,
                          height: 150,
                        ),
                      ),

                      ///Email
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: controllerEmail,
                            style: const TextStyle(fontSize: 20),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 2)),
                                hintText: "E-mail",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                labelText: "E-mail",
                                prefixIcon: const Icon(Icons.mail_outline)),
                            validator: (value) {
                              if (EmailValidator.validate("$value")) {
                                return null;
                              } else {
                                return "Insira um e-mail válido";
                              }
                            },
                          )),

                      ///Senha
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: TextFormField(
                            controller: controllerSenha,
                            style: const TextStyle(fontSize: 20),
                            obscureText: obscureText,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 2)),
                                hintText: "Senha",
                                labelText: "Senha",
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  onPressed: _obscureText,
                                  icon: visibility,
                                )),
                            validator: (value) {
                              if (value.toString().length >= 6) {
                                return null;
                              } else {
                                return "Insira uma senha com mais de 6 dígitos";
                              }
                            },
                            onChanged: (value) {
                              _onChanged(controllerSenha.text);
                            },
                          )),

                      ///ElevatedButton
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: CustomElevatedButton(
                          text: "Entrar",
                          onPressed: () {
                            signIn();
                          },
                        ),
                      ),

                      ///TextButton
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                                context, RouteGenerator.rCadastro);
                          },
                          child: Text(
                            "Não tem conta? cadastre-se!",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
