class Usuario {
  String? id;
  String? nome;
  String? email;
  String? tipoUsuario;
  String? senha;

  double? latitude;
  double? longitude;

  Usuario(this.id, this.nome, this.email, this.tipoUsuario, this.senha,
      this.latitude, this.longitude);

  String verificaTipoUsuario(bool tipoUsuario) {
    return tipoUsuario ? "motorista" : "passageiro";
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "id": this.id,
      "nome": this.nome,
      "email": this.email,
      "tipoUsuario": this.tipoUsuario,
      "latitude": this.latitude,
      "longitude": this.longitude,
    };
    return map;
  }

  factory Usuario.toNull() {
    return Usuario(null, null, null, null, null, null, null);
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      json["id"],
      json["nome"],
      json["email"],
      json["tipoUsuario"],
      json["senha"],
      json["latitude"],
      json["longitude"],
    );
  }

  @override
  String toString() {
    return '{'
        'id: $id, nome: $nome, email: $email, tipoUsuario: $tipoUsuario, senha: $senha, latitude: $latitude, longitude: $longitude,'
        '}';
  }
}
