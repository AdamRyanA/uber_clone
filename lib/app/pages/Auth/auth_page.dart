import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/paths.dart';
import 'package:uber_clone/app/utils/route_generator.dart';
import 'package:uber_clone/app/widgets/custom_elevated_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      var altura = constraint.maxHeight;
      return Scaffold(
          body: Container(
              height: altura,
              /*
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(ImagesPaths.fundo), fit: BoxFit.cover)),
                   */
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 500,
                      child: Image.asset(
                        ImagesPaths.logo,
                        fit: BoxFit.fitWidth,
                      ),
                      //child: Container(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: CustomElevatedButton(
                      text: "Entrar com e-mail",
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context,
                            RouteGenerator.rLoginEmail, (route) => false);
                      },
                    ),
                  )
                ],
              )));
    });
  }
}
