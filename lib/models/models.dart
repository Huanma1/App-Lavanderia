class Prenda {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? icono;

  Prenda({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
  });

  factory Prenda.fromJson(Map<String, dynamic> json) {
    return Prenda(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      icono: json['icono'],
    );
  }
}

class DetalleOrden {
  final int id;
  final int cantidad;
  final Prenda? prenda;

  DetalleOrden({required this.id, required this.cantidad, this.prenda});

  factory DetalleOrden.fromJson(Map<String, dynamic> json) {
    return DetalleOrden(
      id: int.tryParse(json['id'].toString()) ?? 0,
      cantidad: int.tryParse(json['cantidad_usuario'].toString()) ?? 0,
      prenda: json['prenda'] != null ? Prenda.fromJson(json['prenda']) : null,
    );
  }
}

class Orden {
  final int id;
  final String? estado;
  final String fecha;
  final String? fechaSubida;
  final String? observacion;
  final List<DetalleOrden> detalles;

  Orden({
    required this.id,
    this.estado,
    required this.fecha,
    this.fechaSubida,
    this.observacion,
    this.detalles = const [],
  });

  factory Orden.fromJson(Map<String, dynamic> json) {
    var list = json['detalle_ordenes'] as List? ?? [];
    List<DetalleOrden> detallesList = list
        .map((i) => DetalleOrden.fromJson(i))
        .toList();

    return Orden(
      id: int.tryParse(json['id'].toString()) ?? 0,
      estado: json['estado'],
      fecha: json['fecha'],
      fechaSubida: json['fecha_subida'],
      observacion:
          json['usuario_observacion'] ??
          json['observacion'], // Mapeamos el nombre correcto de la columna en BD
      detalles: detallesList,
    );
  }
}
