import math

def calcular_tarifa(distancia_km, peso_kg, es_hora_pico):
    """Calcula la tarifa de un delivery.

    Reglas:
      - Tarifa base: 2.00 (incluye los primeros 3 km)
      - Cada km por encima de 3: +0.50 (se cobran km completos, redondeando hacia arriba)
      - Si el peso supera 5 kg: recargo fijo de +1.50
      - Si es hora pico: +25% sobre el subtotal
      - La tarifa final nunca puede ser menor de 3.00
      - distancia_km y peso_kg negativos deben lanzar ValueError

    Devuelve el importe redondeado a 2 decimales.
    """
    if distancia_km < 0 or peso_kg < 0:
        raise ValueError("La distancia y el peso no pueden ser negativos")
    
    # Tarifa base
    tarifa = 2.00
    
    # KM extra (redondeando hacia arriba)
    if distancia_km > 3:
        km_extra = math.ceil(distancia_km - 3)
        tarifa += km_extra * 0.50
    
    # Recargo por peso
    if peso_kg > 5:
        tarifa += 1.50
    
    # Hora pico
    if es_hora_pico:
        tarifa *= 1.25
    
    # Mínimo
    tarifa = max(tarifa, 3.00)
    
    return round(tarifa, 2)
