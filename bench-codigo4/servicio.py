from typing import List, Optional
from modelos import Pedido, LineaPedido, Cupon
from repositorio import RepositorioPedidos, RepositorioCupones


class PedidoNoEncontrado(Exception):
    pass


class EstadoInvalido(Exception):
    pass


class CuponInvalido(Exception):
    pass


class CuponAgotado(Exception):
    pass


class ServicioPedidos:
    def __init__(self, repo: RepositorioPedidos, cupones: Optional[RepositorioCupones] = None):
        self.repo = repo
        self.cupones = cupones

    def crear_pedido(self, cliente: str, lineas: List[LineaPedido], codigo_cupon: Optional[str] = None) -> Pedido:
        if not cliente:
            raise ValueError("El cliente es obligatorio")
        if not lineas:
            raise ValueError("El pedido debe tener al menos una linea")
        
        descuento = 0.0
        cupon_aplicado = None
        
        if codigo_cupon is not None and self.cupones is not None:
            cupon = self.cupones.obtener(codigo_cupon)
            if cupon is None:
                raise CuponInvalido(f"Cupon '{codigo_cupon}' no existe")
            if cupon.usos_actuales >= cupon.usos_maximos:
                raise CuponAgotado(f"Cupon '{codigo_cupon}' se ha agotado")
            cupon.usos_actuales += 1
            descuento = cupon.porcentaje
            cupon_aplicado = codigo_cupon
        
        pedido = Pedido(
            id=self.repo.nuevo_id(),
            cliente=cliente,
            lineas=list(lineas),
            cupon_aplicado=cupon_aplicado,
            descuento=descuento,
        )
        return self.repo.guardar(pedido)

    def confirmar(self, pedido_id: int) -> Pedido:
        pedido = self._buscar(pedido_id)
        if pedido.estado != "pendiente":
            raise EstadoInvalido(f"No se puede confirmar un pedido en estado {pedido.estado}")
        pedido.estado = "confirmado"
        return self.repo.guardar(pedido)

    def cancelar(self, pedido_id: int) -> Pedido:
        pedido = self._buscar(pedido_id)
        if pedido.estado == "entregado":
            raise EstadoInvalido("No se puede cancelar un pedido ya entregado")
        pedido.estado = "cancelado"
        return self.repo.guardar(pedido)

    def total_facturado(self) -> float:
        confirmados = self.repo.listar_por_estado("confirmado")
        return round(sum(p.total() for p in confirmados), 2)

    def _buscar(self, pedido_id: int) -> Pedido:
        pedido = self.repo.obtener(pedido_id)
        if pedido is None:
            raise PedidoNoEncontrado(f"No existe el pedido {pedido_id}")
        return pedido
