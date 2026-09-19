from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Producto:
    id: int
    nombre: str
    precio: float


@dataclass
class Cupon:
    codigo: str
    porcentaje: float
    usos_maximos: int
    usos_actuales: int = 0


@dataclass
class LineaPedido:
    producto: Producto
    cantidad: int

    def subtotal(self) -> float:
        return round(self.producto.precio * self.cantidad, 2)


@dataclass
class Pedido:
    id: int
    cliente: str
    lineas: List[LineaPedido] = field(default_factory=list)
    estado: str = "pendiente"
    cupon_aplicado: Optional[str] = None
    descuento: float = 0.0

    def total(self) -> float:
        subtotal = sum(l.subtotal() for l in self.lineas)
        return round(subtotal * (1 - self.descuento / 100), 2)
