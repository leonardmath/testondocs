# docassemble/relatorios/validators.py
"""
Validadores de dados para formulários.

Este módulo contém validações simples, síncronas e sem efeitos colaterais.
Todas as funções retornam booleanos e não lançam exceções.
"""

from __future__ import annotations

import re
from datetime import datetime
from typing import Final


# ---------------------------------------------------------------------------
# Regex pré-compiladas (performance + legibilidade)
# ---------------------------------------------------------------------------

_EMAIL_REGEX: Final[re.Pattern[str]] = re.compile(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
)

_ONLY_DIGITS_REGEX: Final[re.Pattern[str]] = re.compile(r"\D+")


# ---------------------------------------------------------------------------
# Helpers internos
# ---------------------------------------------------------------------------

def _somente_digitos(valor: str) -> str:
    """Remove qualquer caractere não numérico da string."""
    return _ONLY_DIGITS_REGEX.sub("", valor)


# ---------------------------------------------------------------------------
# Validadores públicos
# ---------------------------------------------------------------------------

def validar_cnpj(cnpj: str | None) -> bool:
    """
    Valida um CNPJ brasileiro (formato e dígitos verificadores).

    Aceita entrada com ou sem formatação.
    """
    if not cnpj:
        return False

    cnpj_numerico = _somente_digitos(cnpj)

    if len(cnpj_numerico) != 14:
        return False

    # Rejeita sequências inválidas conhecidas (ex: 00000000000000)
    if cnpj_numerico == cnpj_numerico[0] * 14:
        return False

    def calcular_digito(base: str, pesos: list[int]) -> int:
        soma = sum(int(digito) * peso for digito, peso in zip(base, pesos))
        resto = soma % 11
        return 0 if resto < 2 else 11 - resto

    pesos_primeiro = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    pesos_segundo = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

    digito_1 = calcular_digito(cnpj_numerico[:12], pesos_primeiro)
    digito_2 = calcular_digito(cnpj_numerico[:13], pesos_segundo)

    return (
        int(cnpj_numerico[12]) == digito_1
        and int(cnpj_numerico[13]) == digito_2
    )


def validar_email(email: str | None) -> bool:
    """Valida o formato básico de um endereço de e-mail."""
    if not email:
        return False

    return bool(_EMAIL_REGEX.match(email.strip()))


def validar_telefone(telefone: str | None) -> bool:
    """
    Valida telefone brasileiro.

    Aceita:
    - 10 dígitos (fixo)
    - 11 dígitos (celular)
    """
    if not telefone:
        return False

    telefone_numerico = _somente_digitos(telefone)
    return len(telefone_numerico) in (10, 11)


def validar_cep(cep: str | None) -> bool:
    """Valida CEP brasileiro (8 dígitos)."""
    if not cep:
        return False

    return len(_somente_digitos(cep)) == 8


def validar_coordenadas(latitude: float | None, longitude: float | None) -> bool:
    """Valida coordenadas geográficas (WGS84)."""
    if latitude is None or longitude is None:
        return False

    try:
        lat = float(latitude)
        lon = float(longitude)
    except (TypeError, ValueError):
        return False

    return -90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0


def validar_data(data: str | None, formato: str = "%d/%m/%Y") -> bool:
    """Valida uma data conforme o formato informado."""
    if not data:
        return False

    try:
        datetime.strptime(data, formato)
    except ValueError:
        return False

    return True
