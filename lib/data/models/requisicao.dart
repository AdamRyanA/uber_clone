import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uber_clone/data/models/destino.dart';
import 'package:uber_clone/data/models/usuario.dart';

class Requisicao {
  String? id;
  String? status;
  Usuario? passageiro;
  Usuario? motorista;
  Destino? destino;

  Requisicao(
      this.id, this.status, this.passageiro, this.motorista, this.destino) {
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentReference ref = db.collection("requisicoes").doc();
    this.id = ref.id;

    if (kDebugMode) {
      print("Requisicao ID: ${this.id}");
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": this.passageiro?.nome,
      "email": this.passageiro?.email,
      "tipoUsuario": this.passageiro?.tipoUsuario,
      "id": this.passageiro?.id,
      "latitude": this.passageiro?.latitude,
      "longitude": this.passageiro?.longitude,
    };
    Map<String, dynamic> dadosDestino = {
      "rua": this.destino?.rua,
      "numero": this.destino?.numero,
      "bairro": this.destino?.bairro,
      "cep": this.destino?.cep,
      "cidade": this.destino?.cidade,
      "latitude": this.destino?.latitude,
      "longitude": this.destino?.longitude,
    };
    Map<String, dynamic> dadosRequisicao = {
      "id": this.id,
      "status": this.status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino,
    };
    return dadosRequisicao;
  }

  factory Requisicao.toNull() {
    return Requisicao(null, null, null, null, null);
  }

  factory Requisicao.fromJson(Map<String, dynamic> json) {
    return Requisicao(
      json["id"],
      json["status"],
      json["passageiro"],
      json["motorista"],
      json["destino"],
    );
  }

  @override
  String toString() {
    return '{'
        'id: $id, status: $status, passageiro: $passageiro, motorista: $motorista, destino: $destino,'
        '}';
  }
}
