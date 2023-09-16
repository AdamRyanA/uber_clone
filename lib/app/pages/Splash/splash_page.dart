import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/colors.dart';
import 'package:uber_clone/app/utils/paths.dart';
import 'package:uber_clone/domain/usecases/authentication.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  initialLoading() {
    Timer(const Duration(seconds: 3), () {
      Authentication.checkUser(context);
    });
  }

  @override
  void initState() {
    super.initState();
    initialLoading();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      var largura = constraint.maxWidth;
      return Scaffold(
        backgroundColor: blankColor,
        body: Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Image.asset(
              ImagesPaths.logo,
              height: largura,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      );
    });
  }
}
