import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/app/utils/route_generator.dart';
import 'package:uber_clone/data/models/screen_arguments.dart';
import 'package:uber_clone/data/utils/status_requisicao.dart';
import 'package:uber_clone/data/utils/usuario_firebase.dart';
import '../../../domain/usecases/authentication.dart';
import '../../utils/colors.dart';

class PanelDriverPage extends StatefulWidget {
  const PanelDriverPage({Key? key}) : super(key: key);

  @override
  State<PanelDriverPage> createState() => _PanelDriverPageState();
}

class _PanelDriverPageState extends State<PanelDriverPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  List<String> itensMenu = ["Deslogar"];
  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case "Deslogar":
        Authentication.signOut(context);
    }
  }

  final _controller = StreamController<QuerySnapshot>.broadcast();

  //late Map<String, dynamic> _dadosRequisicao;

  StreamController<QuerySnapshot<Object?>> _adicionarListenerRequisicoes() {
    final stream = db
        .collection("requisicoes")
        .where("status", isEqualTo: StatusRequisicao.sAGUARDANDO)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });

    return _controller;
  }

  _recuperaRequisicaoAtivaMotorista() async {
    //Recupera dados do usuario logado
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    //Recupera requisicao ativa
    DocumentSnapshot documentSnapshot = await db
        .collection("requisicao_ativa_motorista")
        .doc(firebaseUser?.uid)
        .get();

    Map<String, dynamic>? dadosRequisicao =
        documentSnapshot.data() as Map<String, dynamic>?;
    //_dadosRequisicao = documentSnapshot.data() as Map<String, dynamic>;

    if (dadosRequisicao == null) {
      _adicionarListenerRequisicoes();
    } else {
      String idRequisicao = dadosRequisicao["id_requisicao"];

      ScreenArguments screenArguments = ScreenArguments();
      screenArguments.idRequisicao = idRequisicao;
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, RouteGenerator.rRide, (route) => false,
          arguments: screenArguments);
    }
  }

  @override
  void initState() {
    super.initState();
    //Authentication.signOut(context);
    //_adicionarListenerRequisicoes();
    _recuperaRequisicaoAtivaMotorista();
    /*
    Recupera requisicao ativa para verificar se motorista está
    atendendo alguma requisição e envia ele para tela de corrida
     */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Motorista"),
        centerTitle: true,
        backgroundColor: darkBlueGray,
        foregroundColor: blankColor,
        actions: [
          PopupMenuButton<String>(
              onSelected: _escolhaMenuItem,
              itemBuilder: (context) {
                return itensMenu.map((String item) {
                  return PopupMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList();
              })
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Carregando requisições"),
                    SizedBox(
                      height: 70,
                    ),
                    CircularProgressIndicator()
                  ],
                ),
              );
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(
                  child: Text("Erro ao carregar os dados"),
                );
              } else {
                QuerySnapshot? querySnapshot = snapshot.data;

                if (querySnapshot!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Você não tem nenhuma requisição :(",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  return ListView.separated(
                    itemCount: querySnapshot.docs.length,
                    separatorBuilder: (context, indice) => const Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                    itemBuilder: (context, indice) {
                      List<DocumentSnapshot> requisicoes =
                          querySnapshot.docs.toList();
                      DocumentSnapshot item = requisicoes[indice];

                      String idRequisicao = item["id"];
                      String nomePassageiro = item["passageiro"]["nome"];
                      String cidade = item["destino"]["cidade"];
                      String rua = item["destino"]["rua"];
                      String numero = item["destino"]["numero"];

                      return ListTile(
                        title: Text(nomePassageiro),
                        subtitle: Text("Destino: $cidade - $rua, $numero"),
                        onTap: () {
                          ScreenArguments screenArguments = ScreenArguments();
                          screenArguments.idRequisicao = idRequisicao;
                          Navigator.pushNamed(context, RouteGenerator.rRide,
                              arguments: screenArguments);
                        },
                      );
                    },
                  );
                }
              }
          }
        },
      ),
    );
  }
}
