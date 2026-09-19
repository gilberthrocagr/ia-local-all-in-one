"""Tests de la funcionalidad NUEVA a implementar: cupones de descuento."""
import pytest
from modelos import Producto, LineaPedido, Cupon
from repositorio import RepositorioPedidos, RepositorioCupones
from servicio import ServicioPedidos, CuponInvalido, CuponAgotado
from api import manejar

P1 = Producto(id=1, nombre="Pizza", precio=10.0)


def _servicio_con_cupones():
    cupones = RepositorioCupones()
    cupones.guardar(Cupon(codigo="BIENVENIDO", porcentaje=10, usos_maximos=2))
    cupones.guardar(Cupon(codigo="AGOTADO", porcentaje=50, usos_maximos=0))
    return ServicioPedidos(RepositorioPedidos(), cupones), cupones


def test_cupon_aplica_descuento():
    s, _ = _servicio_con_cupones()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 3)], codigo_cupon="BIENVENIDO")
    assert p.total() == 27.0  # 30 - 10%


def test_pedido_recuerda_el_cupon():
    s, _ = _servicio_con_cupones()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 1)], codigo_cupon="BIENVENIDO")
    assert p.cupon_aplicado == "BIENVENIDO"


def test_sin_cupon_no_cambia_nada():
    s, _ = _servicio_con_cupones()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 3)])
    assert p.total() == 30.0
    assert p.cupon_aplicado is None


def test_cupon_inexistente():
    s, _ = _servicio_con_cupones()
    with pytest.raises(CuponInvalido):
        s.crear_pedido("Ana", [LineaPedido(P1, 1)], codigo_cupon="NOEXISTE")


def test_cupon_agotado():
    s, _ = _servicio_con_cupones()
    with pytest.raises(CuponAgotado):
        s.crear_pedido("Ana", [LineaPedido(P1, 1)], codigo_cupon="AGOTADO")


def test_cupon_incrementa_usos():
    s, cupones = _servicio_con_cupones()
    s.crear_pedido("Ana", [LineaPedido(P1, 1)], codigo_cupon="BIENVENIDO")
    assert cupones.obtener("BIENVENIDO").usos_actuales == 1


def test_cupon_se_agota_tras_usos_maximos():
    s, _ = _servicio_con_cupones()
    s.crear_pedido("a", [LineaPedido(P1, 1)], codigo_cupon="BIENVENIDO")
    s.crear_pedido("b", [LineaPedido(P1, 1)], codigo_cupon="BIENVENIDO")
    with pytest.raises(CuponAgotado):
        s.crear_pedido("c", [LineaPedido(P1, 1)], codigo_cupon="BIENVENIDO")


def test_total_facturado_usa_total_con_descuento():
    s, _ = _servicio_con_cupones()
    p = s.crear_pedido("Ana", [LineaPedido(P1, 3)], codigo_cupon="BIENVENIDO")
    s.confirmar(p.id)
    assert s.total_facturado() == 27.0


def test_api_acepta_codigo_cupon():
    s, _ = _servicio_con_cupones()
    r = manejar("crear_pedido", {
        "cliente": "Ana",
        "lineas": [{"producto": {"id": 1, "nombre": "Pizza", "precio": 10.0}, "cantidad": 3}],
        "codigo_cupon": "BIENVENIDO",
    }, s)
    assert r["ok"] is True and r["total"] == 27.0


def test_api_error_cupon_invalido():
    s, _ = _servicio_con_cupones()
    r = manejar("crear_pedido", {
        "cliente": "Ana",
        "lineas": [{"producto": {"id": 1, "nombre": "Pizza", "precio": 10.0}, "cantidad": 1}],
        "codigo_cupon": "NOEXISTE",
    }, s)
    assert r["ok"] is False
