def suma(a, b):
    return a + b


def factorial(n):
    """Calcula el factorial de un número entero no negativo de forma recursiva."""
    if n < 0:
        raise ValueError("El factorial no está definido para números negativos.")
    if n == 0 or n == 1:
        return 1
    return n * factorial(n - 1)
