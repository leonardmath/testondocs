# docassemble/relatorios/sanitizers.py
"""
Sanitizadores de dados para limpeza e normalização.

Este módulo contém funções determinísticas que transformam entradas
potencialmente inconsistentes em formatos previsíveis e seguros.
"""

from __future__ import annotations

import re
from typing import Final


# ---------------------------------------------------------------------------
# Regex pré-compiladas
# ---------------------------------------------------------------------------

_ONLY_DIGITS_REGEX: Final[re.Pattern[str]] = re.compile(r"\D+")
_HTML_TAG_REGEX: Final[re.Pattern[str]] = re.compile(r"<[^>]+>")
_MULTIPLE_SPACES_REGEX: Final[re.Pattern[str]] = re.compile(r"\s+")


# ---------------------------------------------------------------------------
# Helpers internos
# ---------------------------------------------------------------------------

def _somente_digitos(valor: str) -> str:
    """Remove qualquer caractere não numérico da string."""
    return _ONLY_DIGITS_REGEX.sub("", valor)


# ---------------------------------------------------------------------------
# Sanitizadores públicos
# ---------------------------------------------------------------------------

def sanitizar_cnpj(cnpj: str | None) -> str:
    """
    Remove qualquer formatação do CNPJ.

    Retorna apenas dígitos ou string vazia.
    """
    if not cnpj:
        return ""

    return _somente_digitos(cnpj)


def sanitizar_telefone(telefone: str | None) -> str:
    """
    Remove formatação do telefone.

    Retorna apenas dígitos ou string vazia.
    """
    if not telefone:
        return ""

    return _somente_digitos(telefone)


def sanitizar_cep(cep: str | None) -> str:
    """
    Remove formatação do CEP.

    Retorna apenas dígitos ou string vazia.
    """
    if not cep:
        return ""

    return _somente_digitos(cep)


def sanitizar_email(email: str | None) -> str:
    """
    Normaliza e-mail para comparação e armazenamento.

    - Remove espaços laterais
    - Converte para lowercase
    """
    if not email:
        return ""

    return email.strip().lower()


def sanitizar_texto(texto: str | None) -> str:
    """
    Sanitiza texto livre para uso seguro em formulários e relatórios.

    Ações realizadas:
    - Remove tags HTML
    - Normaliza espaços em branco
    - Remove espaços excedentes nas extremidades
    """
    if not texto:
        return ""

    texto_limpo = _HTML_TAG_REGEX.sub("", texto)
    texto_limpo = _MULTIPLE_SPACES_REGEX.sub(" ", texto_limpo)

    return texto_limpo.strip()
