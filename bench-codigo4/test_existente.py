"""Tests del comportamiento ACTUAL. El refactor no debe romperlos."""
import pytest
from modelos import Producto, LineaPedido
from repositorio import RepositorioPedidos
from servicio import ServicioPedidos, PedidoNoEncontrado, EstadoInvalido
from api import manejar


def _servicio():
    return ServicioPedidos(RepositorioPedidos())


P1 = Producto(id=1, nombre="Pizza", precio=10.0)
P2 = Producto(id=2, nombre="Refresco", precio=2.5)


def test_crear_y_total():
    s = _servicio()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 2), LineaPedido(P2, 4)])
    assert p.total() == 30.0
    assert p.estado == "pendiente"


def test_confirmar_cambia_estado():
    s = _servicio()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 1)])
    assert s.confirmar(p.id).estado == "confirmado"


def test_no_confirmar_dos_veces():
    s = _servicio()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 1)])
    s.confirmar(p.id)
    with pytest.raises(EstadoInvalido):
        s.confirmar(p.id)


def test_pedido_inexistente():
    with pytest.raises(PedidoNoEncontrado):
        _servicio().confirmar(999)


def test_total_facturado_solo_confirmados():
    s = _servicio()
    a = s.crear_pedido("Ana", [LineaPedido(P1, 1)])
    s.crear_pedido("Luis", [LineaPedido(P1, 5)])
    s.confirmar(a.id)
    assert s.total_facturado() == 10.0


def test_api_crear():
    s = _servicio()
    r = manejar("crear_pedido", {
        "cliente": "Ana",
        "lineas": [{"producto": {"id": 1, "nombre": "Pizza", "precio": 10.0}, "cantidad": 2}],
    }, s)
    assert r["ok"] is True and r["total"] == 20.0


def test_api_error_controlado():
    r = manejar("confirmar", {"pedido_id": 999}, _servicio())
    assert r["ok"] is False and "999" in r["error"]
