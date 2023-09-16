import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/data/models/screen_arguments.dart';
import 'package:uber_clone/data/utils/usuario_firebase.dart';
import '../../../data/models/usuario.dart';
import '../../../data/utils/status_requisicao.dart';
import '../../../domain/usecases/authentication.dart';
import '../../utils/colors.dart';
import '../../utils/paths.dart';
import '../../widgets/custom_elevated_button.dart';

class RidePage extends StatefulWidget {
  final ScreenArguments? screenArguments;

  const RidePage(this.screenArguments, {super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final CameraPosition _posicaoCamera = const CameraPosition(
    target: LatLng(-25.294873004, -54.094897129),
    zoom: 16,
  );
  FirebaseFirestore db = FirebaseFirestore.instance;
  Set<Marker> _marcadores = {};
  late Map<String, dynamic> _dadosRequisicao;

  //Controles para exibição na tela
  String textoBotao = "Aceitar corrida";
  Color corBotao = primaryColor;
  VoidCallback funcaoBotao = () {};
  String _mensagemStatus = "";

  _alterarBotaoPrincipal(String text, Color cor, Function() funcao) {
    setState(() {
      textoBotao = text;
      corBotao = cor;
      funcaoBotao = funcao;
    });
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<Position?> _permissionLocation() async {
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

    _adicionarListenerLocalizacao();

    return null;
  }

  _adicionarListenerLocalizacao() {
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (position != null) {}
    });
  }

  _recuperarUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true);

    if (position != null) {
      //Atualizar localização em tempo real do motorista
    }
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _exibirMarcador(Position local, String icone, String infoWindow) async {
    double pixelRadio = MediaQuery.of(context).devicePixelRatio;

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

  _recuperarRequisicao() async {
    String idRequisicao = "${widget.screenArguments?.idRequisicao}";

    DocumentSnapshot documentSnapshot =
        await db.collection("requisicoes").doc(idRequisicao).get();
  }

  _adicionarListenerRequisicao() async {
    String idRequisicao = _dadosRequisicao["id"];
    db
        .collection("requisicoes")
        .doc(idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (kDebugMode) {
        print("dados recuperados: ${snapshot.data()}");
      }
      if (snapshot.data() != null) {
        _dadosRequisicao = snapshot.data() as Map<String, dynamic>;

        Map<String, dynamic>? dados = snapshot.data();
        String status = dados?["status"];

        switch (status) {
          case StatusRequisicao.sAGUARDANDO:
            _statusAguardando();
          case StatusRequisicao.sCAMINHO:
            _statusACaminho();
          case StatusRequisicao.sVIAGEM:
          case StatusRequisicao.sFINALIZADA:
        }
      }
    });
  }

  _statusAguardando() {
    setState(() {
      _alterarBotaoPrincipal("Aceitar corrida", primaryColor, () {
        _aceitarCorrida();
      });

      double motoristaLat = _dadosRequisicao["motorista"]["latitude"];
      double motoristaLon = _dadosRequisicao["motorista"]["longitude"];

      Position position = Position(
          latitude: motoristaLat,
          longitude: motoristaLon,
          timestamp: null,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          accuracy: 0);
      _exibirMarcador(position, ImagesPaths.motorista, "Motorista");
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);

      _movimentarCamera(cameraPosition);
    });
  }

  _statusACaminho() async {
    _mensagemStatus = " - A caminho do passageiro";
    setState(() {
      _alterarBotaoPrincipal("Iniciar corrida", primaryColor, () {
        _iniciarCorrida();
      });
    });

    double latitudePassageiro = _dadosRequisicao["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeMotorista = _dadosRequisicao["motorista"]["latitude"];
    double longitudeMotorista = _dadosRequisicao["motorista"]["longitude"];

    await _exibirDoisMarcadores(
      LatLng(latitudeMotorista, longitudeMotorista),
      LatLng(latitudePassageiro, longitudePassageiro),
    );

    //-25.343997298162492, -54.254984115719665
    double nLat, nLog, sLat, sLon;

    if (latitudeMotorista <= latitudePassageiro) {
      sLat = latitudeMotorista;
      nLat = latitudePassageiro;
    } else {
      sLat = latitudePassageiro;
      nLat = latitudeMotorista;
    }
    if (longitudeMotorista <= longitudePassageiro) {
      sLon = longitudeMotorista;
      nLog = longitudePassageiro;
    } else {
      sLon = longitudePassageiro;
      nLog = longitudeMotorista;
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

  _iniciarCorrida() {}

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _exibirDoisMarcadores(LatLng motorista, LatLng passageiro) {
    double pixelRadio = MediaQuery.of(context).devicePixelRatio;

    Set<Marker> listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            ImagesPaths.motorista)
        .then((BitmapDescriptor icone) {
      Marker marcador1 = Marker(
          markerId: const MarkerId("marcador-motorista"),
          position: LatLng(motorista.latitude, motorista.longitude),
          infoWindow: const InfoWindow(title: "Local motorista"),
          icon: icone);
      listaMarcadores.add(marcador1);
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            ImagesPaths.passageiro)
        .then((BitmapDescriptor icone) {
      Marker marcador2 = Marker(
          markerId: const MarkerId("marcador-passageiro"),
          position: LatLng(passageiro.latitude, passageiro.longitude),
          infoWindow: const InfoWindow(title: "Local passageiro"),
          icon: icone);
      listaMarcadores.add(marcador2);
    });

    setState(() {
      _marcadores = listaMarcadores;
    });
  }

  _aceitarCorrida() async {
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _dadosRequisicao["motorista"]["latitude"];
    motorista.longitude = _dadosRequisicao["motorista"]["longitude"];

    String idRequisicao = _dadosRequisicao["id"];
    db.collection("requisicoes").doc(idRequisicao).update({
      "motorista": motorista.toMap(),
      "status": StatusRequisicao.sCAMINHO,
    }).then((_) {
      //atualiza Requisicao ativa
      String idPassageiro = _dadosRequisicao["passageiro"]["id"];
      db
          .collection("requisicao_ativa")
          .doc(idPassageiro)
          .update({"status": StatusRequisicao.sCAMINHO});

      //Salvar requisicao ativa para motorista
      String idMotorista = "${motorista.id}";
      db.collection("requisicao_ativa_motorista").doc(idMotorista).set({
        "id_requisicao": idRequisicao,
        "id_usuario": idMotorista,
        "status": StatusRequisicao.sCAMINHO
      });
    });
  }

  PopupMenuButton<String> popupMenuButton() {
    return PopupMenuButton<String>(
        //onSelected: _escolhaMenuItem,
        onSelected: (String escolha) {
      switch (escolha) {
        case "Deslogar":
          Authentication.signOut(context);
      }
    }, itemBuilder: (context) {
      return ["Deslogar"].map((String item) {
        return PopupMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();

    // adicionar listener para mudanças na requisicao
    _adicionarListenerRequisicao();

    //_recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Painel Corrida$_mensagemStatus"),
          centerTitle: true,
          backgroundColor: darkBlueGray,
          foregroundColor: blankColor,
          actions: [popupMenuButton()],
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
}
