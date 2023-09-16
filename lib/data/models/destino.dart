class Destino {
  String? rua;
  String? numero;
  String? cidade;
  String? bairro;
  String? cep;

  double? latitude;
  double? longitude;

  Destino(this.rua, this.numero, this.cidade, this.bairro, this.cep,
      this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "rua": this.rua,
      "numero": this.numero,
      "cidade": this.cidade,
      "bairro": this.bairro,
      "cep": this.cep,
      "latitude": this.latitude,
      "longitude": this.longitude,
    };
    return map;
  }

  factory Destino.toNull() {
    return Destino(null, null, null, null, null, null, null);
  }

  factory Destino.fromJson(Map<String, dynamic> json) {
    return Destino(
      json["rua"],
      json["numero"],
      json["cidade"],
      json["bairro"],
      json["cep"],
      json["latitude"],
      json["longitude"],
    );
  }

  @override
  String toString() {
    return '{'
        'rua: $rua, numero: $numero, cidade: $cidade, bairro: $bairro, cep: $cep, latitude: $latitude, longitude: $longitude,'
        '}';
  }
}
