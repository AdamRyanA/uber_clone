import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber_clone/app/utils/colors.dart';
import 'package:uber_clone/app/utils/paths.dart';
import 'package:uber_clone/app/widgets/custom_elevated_button.dart';
import 'package:uber_clone/data/models/marcadores.dart';
import 'package:uber_clone/data/models/requisicao.dart';
import 'package:uber_clone/data/models/usuario.dart';
import 'package:uber_clone/data/utils/status_requisicao.dart';
import 'package:uber_clone/data/utils/usuario_firebase.dart';
import 'package:uber_clone/domain/usecases/authentication.dart';
import '../../../data/models/destino.dart';
import '../../widgets/show_snackbar.dart';

class PanelPassengerPage extends StatefulWidget {
  const PanelPassengerPage({Key? key}) : super(key: key);

  @override
  State<PanelPassengerPage> createState() => _PanelPassengerPageState();
}

class _PanelPassengerPageState extends State<PanelPassengerPage> {
  final TextEditingController _controllerDestino =
  TextEditingController(text: "rua Castro Alves, 255, São Miguel do Iguaçu");
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  FirebaseFirestore db = FirebaseFirestore.instance;

  Set<Marker> _marcadores = {};
  String _idRequisicao = "";

  bool _exibirCaixaEnderecoDestino = true;
  String textoBotao = "Chamar Uber";
  Color corBotao = primaryColor;
  VoidCallback funcaoBotao = () {};
  late Position _localPassageiro;
  Map<String, dynamic> _dadosRequisicao = {};
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;

  bool loading = false;
  CameraPosition _posicaoCamera = const CameraPosition(
    target: LatLng(-25.294873004, -54.094897129),
    zoom: 16,
  );

  List<String> itensMenu = ["Deslogar"];

  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case "Deslogar":
        Authentication.signOut(context);
    }
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<Position?> permissionLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        print('Location services are disabled.');
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('Location permissions are denied');
        }
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    adicionarListenerLocalizacao();

    return null;
  }

  adicionarListenerLocalizacao() {
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (_idRequisicao.isNotEmpty) {
        if (kDebugMode) {
          print("TESTANDO ID REQUISICAO: $_idRequisicao");
        }
        UsuarioFirebase.atualizarDadosLocalizacao(
            _idRequisicao,
            position.latitude,
            position.longitude,
            "passageiro"
        );
      } else {
        if (kDebugMode) {
          print("TESTANDO POSITION: $position");
        }
        setState(() {
          _localPassageiro = position;
        });
        _statusUberNaoChamado();
      }
    });
  }

  recuperarUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true);

    setState(() {
      if (position != null) {

      }
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  exibirMarcadorPassageiro(Position local) async {
    double pixelRadio = MediaQuery
        .of(context)
        .devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRadio),
        ImagesPaths.passageiro)
        .then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
          markerId: const MarkerId("marcador-passageiro"),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: const InfoWindow(title: "Meu local"),
          icon: icone);

      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  _chamarUber() async {
    String enderecoDestino = _controllerDestino.text;
    if (enderecoDestino.isNotEmpty) {
      if (loading == false) {
        setState(() {
          loading == true;
        });

        try {
          List<Location> listaEndereco =
          await locationFromAddress(enderecoDestino);

          if (listaEndereco.isNotEmpty) {
            Location location = listaEndereco[0];
            List<Placemark> placemark = await placemarkFromCoordinates(
                location.latitude, location.longitude);

            Placemark endereco = placemark[0];

            Destino destino = Destino.toNull();
            destino.cidade = endereco.subAdministrativeArea;
            destino.cep = endereco.postalCode;
            destino.bairro = endereco.subLocality;
            destino.rua = endereco.thoroughfare;
            destino.numero = endereco.subThoroughfare;

            destino.latitude = location.latitude;
            destino.longitude = location.longitude;

            String enderecoConfirmacao;
            enderecoConfirmacao = "\n Cidade: ${destino.cidade}"
                "\n Rua: ${destino.rua}, ${destino.numero}"
                "\n Bairro: ${destino.bairro}"
                "\n Cep: ${destino.cep}";

            if (!context.mounted) return;
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    titleTextStyle: const TextStyle(color: Colors.red),
                    title: const Text("Confirmação de endereço"),
                    content: Text(enderecoConfirmacao),
                    contentPadding: const EdgeInsets.all(16),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar",
                              style: TextStyle(color: Colors.red))),
                      TextButton(
                          onPressed: () {
                            _salvarRequisicao(destino);

                            Navigator.pop(context);
                          },
                          child: const Text("Confirmar",
                              style: TextStyle(color: Colors.green))),
                    ],
                  );
                });
          }
        } catch (e) {
          if (kDebugMode) {
            print("Erro: $e");
          }
          if (!context.mounted) return;
          showSnackbar(
              context, 'Não foi possível encontrar o endereço.\nErro: $e');
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
      showSnackbar(context, 'Insira um Endereço');
      if (kDebugMode) {
        print("Insira um Endereço");
      }
    }
  }

  _salvarRequisicao(Destino destino) async {
    /*
    + requisicao
      + ID_REQUISICAO
        + destino (rua, endereco, latitude...)
        + passageiro (nome, email...)
        + motorista (nome, email...)
        + status (aguardando, a_caminho...finalizada)
     */

    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro.latitude = _localPassageiro.latitude;
    passageiro.longitude = _localPassageiro.longitude;

    Requisicao requisicao = Requisicao.toNull();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.sAGUARDANDO;

    ///Salvar requisicao
    db.collection('requisicoes').doc(requisicao.id).set(requisicao.toMap());

    ///Salvar requisicao Ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva["id_usuario"] = passageiro.id;
    dadosRequisicaoAtiva["status"] = StatusRequisicao.sAGUARDANDO;

    db
        .collection("requisicao_ativa")
        .doc(passageiro.id)
        .set(dadosRequisicaoAtiva);

    if (_streamSubscriptionRequisicoes == null) {
      _adicionarListenerRequisicao("${requisicao.id}");
    }
  }

  _alterarBotaoPrincipal(String text, Color cor, Function() funcao) {
    setState(() {
      textoBotao = text;
      corBotao = cor;
      funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado() {
    setState(() {
      _exibirCaixaEnderecoDestino = true;
      _alterarBotaoPrincipal("Chamar Uber", primaryColor, () {
        _chamarUber();
      });

      if (_localPassageiro != null) {
        Position position = Position(
            longitude: _localPassageiro.longitude,
            latitude: _localPassageiro.latitude,
            timestamp: null,
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0
        );
        exibirMarcadorPassageiro(position);

        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 19);
        _movimentarCamera(_posicaoCamera);
      }
    });
  }

  statusAguardando() {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
      _alterarBotaoPrincipal("Cancelar", Colors.red, () {
        _cancelarUber();
      });

      double passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
      double passageiroLon = _dadosRequisicao["passageiro"]["longitude"];
      Position position = Position(
          longitude: passageiroLon,
          latitude: passageiroLat,
          timestamp: null,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0
      );
      exibirMarcadorPassageiro(position);

      _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);
      _movimentarCamera(_posicaoCamera);
    });
  }

  _statusACaminho() async {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
      _alterarBotaoPrincipal("Motorista a caminho", Colors.grey, () {});
    });

    double latitudeDestino = _dadosRequisicao["passageiro"]["latitude"];
    double longitudeDestino = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng(latitudeOrigem, longitudeOrigem),
        ImagesPaths.motorista,
        "Local motorista");
    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        ImagesPaths.passageiro,
        "Local passageiro");
    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem() async {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
      _alterarBotaoPrincipal("Finalizar corrida", Colors.grey, () {});
    });

    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng(latitudeOrigem, longitudeOrigem),
        ImagesPaths.motorista,
        "Local motorista");
    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        ImagesPaths.destino,
        "Local destino");
    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusFinalizada() async {
    //Calcular valor da corrida

    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["origem"]["longitude"];


    double distanciaEmMetros = Geolocator.distanceBetween(
        latitudeOrigem,
        longitudeOrigem,
        latitudeDestino,
        longitudeDestino);

    double distanciaKm = distanciaEmMetros / 1000;

    //8 é o valor cobrado por KM
    double valorViagem = distanciaKm * 8;

    var f = NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = f.format(valorViagem);

    setState(() {
      _alterarBotaoPrincipal(
          "Total - R\$$valorViagemFormatado", Colors.green, () {});
    });

    _marcadores = {};
    Position position = Position(
        latitude: latitudeDestino,
        longitude: longitudeDestino,
        timestamp: null,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        accuracy: 0);
    _exibirMarcador(position, ImagesPaths.destino, "Destino");
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 19);

    _movimentarCamera(cameraPosition);
  }

  _statusConfirmada() {
    if (_streamSubscriptionRequisicoes != null) {
      _streamSubscriptionRequisicoes!.cancel();
      _streamSubscriptionRequisicoes = null;
    }
    setState(() {
      _exibirCaixaEnderecoDestino = true;
      _alterarBotaoPrincipal("Chamar Uber", primaryColor, () {
        _chamarUber();
      });
      _dadosRequisicao = {};

      double passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
      double passageiroLon = _dadosRequisicao["passageiro"]["longitude"];
      Position position = Position(
          longitude: passageiroLon,
          latitude: passageiroLat,
          timestamp: null,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0
      );
      exibirMarcadorPassageiro(position);

      _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);
      _movimentarCamera(_posicaoCamera);
    });
  }

  _exibirMarcador(Position local, String icone, String infoWindow) async {
    double pixelRadio = MediaQuery
        .of(context)
        .devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRadio), icone)
        .then((BitmapDescriptor bitmapDescriptor) {
      Marker marcador = Marker(
          markerId: MarkerId(icone),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: InfoWindow(title: infoWindow),
          icon: bitmapDescriptor);

      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

  _exibirCentralizarDoisMarcadores(Marcador marcadorOrigem,
      Marcador marcadorDestino) async {
    double latitudeOrigem = marcadorOrigem.local.latitude;
    double longitudeOrigem = marcadorOrigem.local.longitude;

    double latitudeDestino = marcadorDestino.local.latitude;
    double longitudeDestino = marcadorDestino.local.longitude;

    await _exibirDoisMarcadores(
        marcadorOrigem,
        marcadorDestino
    );

    //-25.343997298162492, -54.254984115719665
    double nLat, nLog, sLat, sLon;

    if (latitudeOrigem <= latitudeDestino) {
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    } else {
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }
    if (longitudeOrigem <= longitudeDestino) {
      sLon = longitudeOrigem;
      nLog = longitudeDestino;
    } else {
      sLon = longitudeDestino;
      nLog = longitudeOrigem;
    }

    try {
      _movimentarCameraBounds(LatLngBounds(
        northeast: LatLng(nLat, nLog),
        //northeast: LatLng(latitudeMotorista, longitudeMotorista),
        southwest: LatLng(sLat, sLon),
        //southwest: LatLng(latitudePassageiro, longitudePassageiro),
      ));
    } catch (e) {
      if (kDebugMode) {
        print("Movimentar Camera Bounds ERROR: $e");
      }
    }
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

    _exibirDoisMarcadores(Marcador marcadorOrigem, Marcador marcadorDestino) {
      double pixelRadio = MediaQuery
          .of(context)
          .devicePixelRatio;

      LatLng latLngOrigem = marcadorOrigem.local;
      LatLng latLngDestino = marcadorDestino.local;

      Set<Marker> listaMarcadores = {};
      BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: pixelRadio),
          marcadorOrigem.caminhoImagem)
          .then((BitmapDescriptor icone) {
        Marker marcOrigem = Marker(
            markerId: MarkerId(marcadorOrigem.caminhoImagem),
            position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
            infoWindow: InfoWindow(title: marcadorOrigem.titulo),
            icon: icone);
        listaMarcadores.add(marcOrigem);
      });
      BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: pixelRadio),
          marcadorDestino.caminhoImagem)
          .then((BitmapDescriptor icone) {
        Marker marcDestino = Marker(
            markerId: MarkerId(marcadorDestino.caminhoImagem),
            position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
            infoWindow: InfoWindow(title: marcadorDestino.titulo),
            icon: icone);
        listaMarcadores.add(marcDestino);
      });

      setState(() {
        _marcadores = listaMarcadores;
      });
    }

    _cancelarUber() async {
      User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

      db
          .collection("requisicoes")
          .doc(_idRequisicao)
          .update({"status": StatusRequisicao.sCANCELADA}).then((_) {
        db.collection("requisicao_ativa").doc(firebaseUser?.uid).delete();
      });

      _statusUberNaoChamado();

      if (_streamSubscriptionRequisicoes != null) {
        _streamSubscriptionRequisicoes!.cancel();
        _streamSubscriptionRequisicoes = null;
      }
    }

    _recuperarRequisicaoAtiva() async {
      User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

      DocumentSnapshot documentSnapshot = await db
          .collection("requisicao_ativa")
          .doc(firebaseUser?.uid)
          .get();

      if (documentSnapshot.data() != null) {
        Map<String, dynamic>? dados = documentSnapshot.data() as Map<
            String,
            dynamic>?;
        _idRequisicao = dados?["id_requisicao"];
        _adicionarListenerRequisicao(_idRequisicao);
      } else {
        _statusUberNaoChamado();
      }
    }

    _adicionarListenerRequisicao(String idRequisicao) async {
      _streamSubscriptionRequisicoes = db.collection("requisicoes")
          .doc(idRequisicao)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.data() != null) {
          Map<String, dynamic>? dados = snapshot.data();
          _dadosRequisicao = dados!;
          String status = dados["status"];
          _idRequisicao = dados["id"];

          switch (status) {
            case StatusRequisicao.sAGUARDANDO:
              statusAguardando();
            case StatusRequisicao.sCAMINHO:
              _statusACaminho();
            case StatusRequisicao.sVIAGEM:
              _statusEmViagem();
            case StatusRequisicao.sFINALIZADA:
              _statusFinalizada();
            case StatusRequisicao.sCONFIRMADA:
              _statusConfirmada();
          }
        }
      });
    }


    @override
    void initState() {
      super.initState();
      _recuperarRequisicaoAtiva();

      permissionLocation();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Passageiro"),
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
          body: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _posicaoCamera,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
                markers: _marcadores,
              ),
              Visibility(
                visible: _exibirCaixaEnderecoDestino,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white),
                          child: TextFormField(
                            style: const TextStyle(fontSize: 20),
                            readOnly: true,
                            decoration: InputDecoration(
                              icon: Container(
                                margin: const EdgeInsets.only(left: 15),
                                width: 20,
                                //height: 30,
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              hintText: "Meu local",
                              border: InputBorder.none,
                              //contentPadding: EdgeInsets.only(left: 15, top: 16)
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 55,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white),
                          child: TextFormField(
                            controller: _controllerDestino,
                            style: const TextStyle(fontSize: 20),
                            decoration: InputDecoration(
                              icon: Container(
                                margin: const EdgeInsets.only(left: 15),
                                width: 20,
                                child: const Center(
                                  child: Icon(
                                    Icons.local_taxi,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              hintText: "Digite o destino",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                  right: 0,
                  left: 0,
                  bottom: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CustomElevatedButton(
                      text: textoBotao,
                      backgroundColor: corBotao,
                      onPressed: funcaoBotao,
                    ),
                  ))
            ],
          ));
    }
    @override
    void dispose() {
      super.dispose();
      _streamSubscriptionRequisicoes?.cancel();
      _streamSubscriptionRequisicoes = null;
    }
  }