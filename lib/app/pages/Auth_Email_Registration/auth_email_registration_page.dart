import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/colors.dart';
import 'package:uber_clone/domain/usecases/authentication.dart';
import '../../../data/models/usuario.dart';
import '../../widgets/custom_elevated_button.dart';

class AuthEmailRegistrationPage extends StatefulWidget {
  const AuthEmailRegistrationPage({Key? key}) : super(key: key);

  @override
  State<AuthEmailRegistrationPage> createState() =>
      _AuthEmailRegistrationPageState();
}

class _AuthEmailRegistrationPageState extends State<AuthEmailRegistrationPage> {
  TextEditingController controllerNome = TextEditingController(text: "Adam");
  TextEditingController controllerEmail =
      TextEditingController(text: "adam@gmail.com");
  TextEditingController controllerSenha =
      TextEditingController(text: "123456789");
  TextEditingController controllerSenhaConfirm =
      TextEditingController(text: "123456789");
  final _formKey = GlobalKey<FormState>();

  bool vazio = true;
  bool obscureText = true;
  bool tipoUsuario = false;

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

  createUser() async {
    if (_formKey.currentState!.validate()) {
      if (loading == false) {
        setState(() {
          loading == true;
        });

        Usuario usuario = Usuario.toNull();
        usuario.nome = controllerNome.text;
        usuario.email = controllerEmail.text;
        usuario.senha = controllerSenha.text;
        usuario.tipoUsuario = usuario.verificaTipoUsuario(tipoUsuario);

        await Authentication.createUser(context, usuario);

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
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        backgroundColor: blankColor,
        appBar: AppBar(
          title: const Text("Cadastro"),
          centerTitle: true,
          backgroundColor: darkBlueGray,
          foregroundColor: blankColor,
        ),
        body: SingleChildScrollView(
            child: Center(
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
                          ///Nome
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                controller: controllerNome,
                                style: const TextStyle(fontSize: 20),
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey, width: 2)),
                                    hintText: "Nome",
                                    labelText: "Nome",
                                    prefixIcon: Icon(Icons.mail_outline)),
                                validator: (value) {
                                  if (value.toString().length >= 3) {
                                    return null;
                                  } else {
                                    return "Insira seu nome";
                                  }
                                },
                              )),

                          ///Email
                          Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextFormField(
                                controller: controllerEmail,
                                style: const TextStyle(fontSize: 20),
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey, width: 2)),
                                    hintText: "E-mail",
                                    labelText: "E-mail",
                                    prefixIcon: Icon(Icons.mail_outline)),
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

                          ///SenhaConfirm
                          Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextFormField(
                                controller: controllerSenhaConfirm,
                                style: const TextStyle(fontSize: 20),
                                obscureText: obscureText,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey, width: 2)),
                                    hintText: "Confirmar Senha",
                                    labelText: "Confirmar Senha",
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      onPressed: _obscureText,
                                      icon: visibility,
                                    )),
                                validator: (value) {
                                  if (controllerSenha.text ==
                                      controllerSenhaConfirm.text) {
                                    return null;
                                  } else {
                                    return "As senhas não são iguais";
                                  }
                                },
                                onChanged: (value) {
                                  _onChanged(controllerSenhaConfirm.text);
                                },
                              )),

                          ///Decisão
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text(
                                    "Passageiro",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                Switch(
                                  value: tipoUsuario,
                                  onChanged: (valor) {
                                    setState(() {
                                      tipoUsuario = valor;
                                    });
                                  },
                                  //activeColor: darkBlueGray,
                                  activeTrackColor: Colors.blueGrey[700],
                                  //inactiveThumbColor: darkBlueGray,
                                  inactiveTrackColor: Colors.blueGrey[100],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "Motorista",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                )
                              ],
                            ),
                          ),

                          ///ElevatedButton
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: CustomElevatedButton(
                              text: "Cadastrar",
                              onPressed: () {
                                createUser();
                              },
                            ),
                          ),
                        ]),
                  )),
        )),
      );
    });
  }
}
