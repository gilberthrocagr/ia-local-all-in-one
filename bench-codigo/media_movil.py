def media_movil(valores, ventana):
    """Calcula la media movil de una lista de numeros.

    media_movil([1,2,3,4,5], 3) debe devolver [2.0, 3.0, 4.0]
    """
    resultado = []
    for i in range(ventana - 1, len(valores)):
        resultado.append(sum(valores[i-ventana+1:i+1]) / ventana)
    return resultado
