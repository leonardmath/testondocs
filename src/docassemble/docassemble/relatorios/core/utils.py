# docassemble/relatorios/utils.py
"""
Funções utilitárias para manipulação de dados.
"""

import re
from datetime import datetime
from typing import Optional, Dict, Any


def limpar_cnpj(cnpj: str) -> str:
    """Remove formatação do CNPJ"""
    if not cnpj:
        return ""
    return re.sub(r'[^0-9]', '', str(cnpj))


def formatar_cnpj(cnpj: str) -> str:
    """Formata CNPJ: XX.XXX.XXX/XXXX-XX"""
    limpo = limpar_cnpj(cnpj)
    if len(limpo) != 14:
        return cnpj
    return f"{limpo[:2]}.{limpo[2:5]}.{limpo[5:8]}/{limpo[8:12]}-{limpo[12:]}"


def limpar_telefone(telefone: str) -> str:
    """Remove formatação do telefone"""
    if not telefone:
        return ""
    return re.sub(r'[^0-9]', '', str(telefone))


def formatar_telefone(telefone: str) -> str:
    """Formata telefone: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX"""
    limpo = limpar_telefone(telefone)
    if len(limpo) == 11:
        return f"({limpo[:2]}) {limpo[2:7]}-{limpo[7:]}"
    elif len(limpo) == 10:
        return f"({limpo[:2]}) {limpo[2:6]}-{limpo[6:]}"
    return telefone


def limpar_cep(cep: str) -> str:
    """Remove formatação do CEP"""
    if not cep:
        return ""
    return re.sub(r'[^0-9]', '', str(cep))


def formatar_cep(cep: str) -> str:
    """Formata CEP: XXXXX-XXX"""
    limpo = limpar_cep(cep)
    if len(limpo) != 8:
        return cep
    return f"{limpo[:5]}-{limpo[5:]}"


def gerar_protocolo(prefixo: str = "PA") -> str:
    """
    Gera protocolo único.
    
    Args:
        prefixo: Prefixo do protocolo (PA=Passivo, PG=PGRS, NR=NR13)
    
    Returns:
        Protocolo no formato: PA-20241224-153045
    """
    agora = datetime.now()
    return f"{prefixo}-{agora.strftime('%Y%m%d-%H%M%S')}"


def campo_preenchido(valor: Any) -> bool:
    """
    Verifica se um campo está preenchido de forma significativa.
    
    Returns:
        True se o campo tem valor útil, False caso contrário
    """
    if valor is None:
        return False
    if isinstance(valor, str) and valor.strip() == '':
        return False
    if isinstance(valor, (list, dict)) and len(valor) == 0:
        return False
    if isinstance(valor, (int, float)) and valor == 0:
        return False  # Ou True dependendo do contexto
    return True


def extrair_dados_bloco(obj, campos: list) -> Dict[str, Any]:
    """
    Extrai dados de um objeto Docassemble para um dict.
    
    Args:
        obj: Objeto Docassemble (DAObject)
        campos: Lista de nomes de campos a extrair
    
    Returns:
        Dict com campos extraídos
    """
    dados = {}
    for campo in campos:
        try:
            valor = getattr(obj, campo, None)
            if campo_preenchido(valor):
                dados[campo] = valor
        except:
            pass
    return dados


def calcular_tempo_preenchimento(inicio: datetime, fim: datetime) -> int:
    """Calcula tempo de preenchimento em minutos"""
    if not inicio or not fim:
        return 0
    delta = fim - inicio
    return int(delta.total_seconds() / 60)