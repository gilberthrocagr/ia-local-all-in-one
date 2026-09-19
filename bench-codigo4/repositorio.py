from typing import Dict, List, Optional
from modelos import Pedido, Cupon


class RepositorioPedidos:
    """Almacen en memoria de pedidos."""

    def __init__(self):
        self._pedidos: Dict[int, Pedido] = {}
        self._siguiente_id = 1

    def nuevo_id(self) -> int:
        id_ = self._siguiente_id
        self._siguiente_id += 1
        return id_

    def guardar(self, pedido: Pedido) -> Pedido:
        self._pedidos[pedido.id] = pedido
        return pedido

    def obtener(self, pedido_id: int) -> Optional[Pedido]:
        return self._pedidos.get(pedido_id)

    def listar_por_estado(self, estado: str) -> List[Pedido]:
        return [p for p in self._pedidos.values() if p.estado == estado]


class RepositorioCupones:
    """Almacen en memoria de cupones."""

    def __init__(self):
        self._cupones: Dict[str, Cupon] = {}

    def guardar(self, cupon: Cupon) -> Cupon:
        self._cupones[cupon.codigo] = cupon
        return cupon

    def obtener(self, codigo: str) -> Optional[Cupon]:
        return self._cupones.get(codigo)
