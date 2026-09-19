from media_movil import media_movil

def test_basico():
    assert media_movil([1,2,3,4,5], 3) == [2.0, 3.0, 4.0]

def test_ventana_1():
    assert media_movil([5,10,15], 1) == [5.0, 10.0, 15.0]

def test_ventana_igual_longitud():
    assert media_movil([2,4,6], 3) == [4.0]
