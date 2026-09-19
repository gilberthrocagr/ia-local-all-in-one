from reportes import (reporte_pedidos_dia, reporte_pedidos_semana,
                      reporte_pedidos_mes, exportar)

PEDIDOS = [
    {"estado": "entregado", "monto": 10.0},
    {"estado": "cancelado", "monto": 99.0},
    {"estado": "entregado", "monto": 20.0},
]

def test_dia():
    r = reporte_pedidos_dia(PEDIDOS)
    assert r == {"titulo": "Reporte diario de pedidos", "total": 30.0,
                 "cantidad": 2, "promedio": 15.0}

def test_semana():
    assert reporte_pedidos_semana(PEDIDOS)["titulo"] == "Reporte semanal de pedidos"

def test_mes():
    assert reporte_pedidos_mes(PEDIDOS)["total"] == 30.0

def test_vacio_no_divide_por_cero():
    assert reporte_pedidos_dia([])["promedio"] == 0

def test_exportar():
    assert '"total": 30.0' in exportar(reporte_pedidos_dia(PEDIDOS))
