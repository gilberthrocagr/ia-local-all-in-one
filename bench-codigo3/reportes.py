import json


def _calcular_reporte(pedidos, titulo):
    total = 0
    cantidad = 0
    for p in pedidos:
        if p["estado"] == "entregado":
            total += p["monto"]
            cantidad += 1
    promedio = total / cantidad if cantidad else 0
    return {
        "titulo": titulo,
        "total": round(total, 2),
        "cantidad": cantidad,
        "promedio": round(promedio, 2),
    }


def reporte_pedidos_dia(pedidos):
    return _calcular_reporte(pedidos, "Reporte diario de pedidos")


def reporte_pedidos_semana(pedidos):
    return _calcular_reporte(pedidos, "Reporte semanal de pedidos")


def reporte_pedidos_mes(pedidos):
    return _calcular_reporte(pedidos, "Reporte mensual de pedidos")


def exportar(reporte):
    return json.dumps(reporte, ensure_ascii=False)
