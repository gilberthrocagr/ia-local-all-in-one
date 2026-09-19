from modelos import Producto, LineaPedido
from servicio import ServicioPedidos, PedidoNoEncontrado, EstadoInvalido, CuponInvalido, CuponAgotado


def manejar(ruta: str, payload: dict, servicio: ServicioPedidos) -> dict:
    """Router minimalista. Devuelve {'ok': bool, ...}."""
    try:
        if ruta == "crear_pedido":
            lineas = [
                LineaPedido(
                    producto=Producto(**l["producto"]),
                    cantidad=l["cantidad"],
                )
                for l in payload["lineas"]
            ]
            codigo_cupon = payload.get("codigo_cupon")
            pedido = servicio.crear_pedido(payload["cliente"], lineas, codigo_cupon)
            return {"ok": True, "pedido_id": pedido.id, "total": pedido.total()}

        if ruta == "confirmar":
            pedido = servicio.confirmar(payload["pedido_id"])
            return {"ok": True, "estado": pedido.estado, "total": pedido.total()}

        if ruta == "cancelar":
            pedido = servicio.cancelar(payload["pedido_id"])
            return {"ok": True, "estado": pedido.estado}

        if ruta == "total_facturado":
            return {"ok": True, "total": servicio.total_facturado()}

        return {"ok": False, "error": f"ruta desconocida: {ruta}"}

    except (PedidoNoEncontrado, EstadoInvalido, ValueError, CuponInvalido, CuponAgotado) as e:
        return {"ok": False, "error": str(e)}
