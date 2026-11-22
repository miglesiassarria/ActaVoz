#!/usr/bin/env python3
"""Exploración aislada de cobertura ante rechazo por longitud; no es implementación."""
from dataclasses import dataclass


class ContextoExcedido(Exception):
    pass


@dataclass
class ProveedorSimulado:
    limite: int
    llamadas: list[str]

    def enviar(self, texto: str) -> str:
        if len(texto) > self.limite:
            raise ContextoExcedido()
        self.llamadas.append(texto)
        return f"parte-{len(self.llamadas)}"


def dividir_sin_perdida(texto: str, proveedor: ProveedorSimulado) -> list[str]:
    try:
        return [proveedor.enviar(texto)]
    except ContextoExcedido:
        if len(texto) <= 1:
            raise
        mitad = len(texto) // 2
        return dividir_sin_perdida(texto[:mitad], proveedor) + dividir_sin_perdida(texto[mitad:], proveedor)


def main() -> None:
    original = "Álvaro acordó revisar el proyecto mañana.\n" * 31
    proveedor = ProveedorSimulado(limite=128, llamadas=[])
    resultados = dividir_sin_perdida(original, proveedor)
    assert len(resultados) > 1
    assert "".join(proveedor.llamadas) == original
    try:
        dividir_sin_perdida("texto", ProveedorSimulado(limite=0, llamadas=[]))
    except ContextoExcedido:
        pass
    else:
        raise AssertionError("El rechazo irreducible debe propagarse")
    print(f"OK: cobertura exacta en {len(resultados)} partes; rechazo irreducible propagado")
    print("No se verifica síntesis, historial, streaming ni equivalencia semántica.")


if __name__ == "__main__":
    main()
