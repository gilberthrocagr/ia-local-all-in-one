import pytest
from tarifa import calcular_tarifa

def test_minimo():
    # 2.00 base, pero el minimo es 3.00
    assert calcular_tarifa(1, 1, False) == 3.00

def test_km_extra():
    # 3 km incluidos, 2 km extra = 2.00 + 1.00 = 3.00
    assert calcular_tarifa(5, 1, False) == 3.00

def test_km_fraccionado_redondea_arriba():
    # 5.1 km -> 2.1 km extra -> se cobran 3 km = 2.00 + 1.50 = 3.50
    assert calcular_tarifa(5.1, 1, False) == 3.50

def test_recargo_peso():
    # 5 km, 6 kg: 2.00 + 1.00 + 1.50 = 4.50
    assert calcular_tarifa(5, 6, False) == 4.50

def test_peso_limite_no_recarga():
    # exactamente 5 kg NO recarga
    assert calcular_tarifa(5, 5, False) == 3.00

def test_hora_pico():
    # 4.50 * 1.25 = 5.625 -> 5.63
    assert calcular_tarifa(5, 6, True) == 5.63

def test_minimo_aplica_tras_hora_pico():
    # 2.00 * 1.25 = 2.50 -> pero el minimo es 3.00
    assert calcular_tarifa(1, 1, True) == 3.00

def test_negativos():
    with pytest.raises(ValueError):
        calcular_tarifa(-1, 1, False)
    with pytest.raises(ValueError):
        calcular_tarifa(1, -1, False)
