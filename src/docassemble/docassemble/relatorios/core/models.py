# docassemble/models.py
"""
Schemas Pydantic para validação e serialização de dados.
Cada modelo representa um bloco reutilizável de dados.
"""

from pydantic import BaseModel, Field, validator, EmailStr
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from enum import Enum
import re


# =============================================================================
# ENUMS - Valores padronizados
# =============================================================================

class TipoRelatorio(str, Enum):
    PASSIVO_AMBIENTAL = "passivo_ambiental"
    PGRS = "pgrs"
    NR13 = "nr13"


class Prioridade(str, Enum):
    NORMAL = "normal"
    URGENTE = "urgente"
    EXPRESS = "express"


class UF(str, Enum):
    AC = "AC"
    AL = "AL"
    AP = "AP"
    AM = "AM"
    BA = "BA"
    CE = "CE"
    DF = "DF"
    ES = "ES"
    GO = "GO"
    MA = "MA"
    MT = "MT"
    MS = "MS"
    MG = "MG"
    PA = "PA"
    PB = "PB"
    PR = "PR"
    PE = "PE"
    PI = "PI"
    RJ = "RJ"
    RN = "RN"
    RS = "RS"
    RO = "RO"
    RR = "RR"
    SC = "SC"
    SP = "SP"
    SE = "SE"
    TO = "TO"


# =============================================================================
# BLOCOS REUTILIZÁVEIS - Models Base
# =============================================================================

class DadosCadastraisModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Dados Cadastrais da Empresa
    Usado em: Passivo, PGRS, NR13, Licenciamento, etc.
    """
    cnpj: Optional[str] = Field(None, description="CNPJ sem formatação (14 dígitos)")
    razao_social: Optional[str] = Field(None, max_length=200)
    nome_fantasia: Optional[str] = Field(None, max_length=200)
    inscricao_estadual: Optional[str] = None
    inscricao_municipal: Optional[str] = None
    
    # Metadados de busca
    cnpj_origem_busca: Optional[bool] = Field(
        False, 
        description="Se dados vieram de busca automática"
    )
    cnpj_busca_timestamp: Optional[datetime] = None
    
    @validator('cnpj')
    def validar_cnpj(cls, v):
        if v is None:
            return v
        limpo = re.sub(r'[^0-9]', '', str(v))
        if len(limpo) != 14:
            return None  # Não bloqueia, retorna None
        return limpo
    
    class Config:
        json_schema_extra = {
            "example": {
                "cnpj": "12345678000190",
                "razao_social": "POSTO EXEMPLO LTDA",
                "nome_fantasia": "Posto Exemplo"
            }
        }


class ContatoModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Dados de Contato
    Usado em: Todas as entrevistas
    """
    email: Optional[EmailStr] = None
    telefone: Optional[str] = Field(None, description="Telefone sem formatação (10-11 dígitos)")
    celular: Optional[str] = None
    responsavel_nome: Optional[str] = Field(None, max_length=200)
    responsavel_cargo: Optional[str] = Field(None, max_length=100)
    responsavel_cpf: Optional[str] = None
    
    @validator('telefone', 'celular')
    def validar_telefone(cls, v):
        if v is None:
            return v
        limpo = re.sub(r'[^0-9]', '', str(v))
        if len(limpo) not in [10, 11]:
            return None
        return limpo
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "contato@posto.com",
                "telefone": "44999887766",
                "responsavel_nome": "João Silva"
            }
        }


class EnderecoModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Endereço Completo
    Usado em: Todas as entrevistas
    """
    cep: Optional[str] = Field(None, description="CEP sem formatação (8 dígitos)")
    logradouro: Optional[str] = Field(None, max_length=200)
    numero: Optional[str] = Field(None, max_length=20)
    complemento: Optional[str] = Field(None, max_length=100)
    bairro: Optional[str] = Field(None, max_length=100)
    municipio: Optional[str] = Field(None, max_length=100)
    uf: Optional[UF] = None
    
    # Metadados de busca
    cep_origem_busca: Optional[bool] = False
    cep_busca_timestamp: Optional[datetime] = None
    
    @validator('cep')
    def validar_cep(cls, v):
        if v is None:
            return v
        limpo = re.sub(r'[^0-9]', '', str(v))
        if len(limpo) != 8:
            return None
        return limpo
    
    def endereco_completo(self) -> str:
        """Retorna endereço formatado"""
        partes = []
        if self.logradouro:
            partes.append(self.logradouro)
        if self.numero:
            partes.append(f"nº {self.numero}")
        if self.complemento:
            partes.append(self.complemento)
        if self.bairro:
            partes.append(f"- {self.bairro}")
        if self.municipio and self.uf:
            partes.append(f"- {self.municipio}/{self.uf}")
        if self.cep:
            cep_formatado = f"{self.cep[:5]}-{self.cep[5:]}"
            partes.append(f"- CEP {cep_formatado}")
        return " ".join(partes)


class LocalizacaoModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Localização Geográfica
    Usado em: Passivo, Licenciamento, Monitoramento
    """
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    area_m2: Optional[float] = Field(None, gt=0, description="Área em metros quadrados")
    area_ha: Optional[float] = Field(None, gt=0, description="Área em hectares")
    
    # Arquivos geoespaciais
    arquivo_kmz_path: Optional[str] = None
    arquivo_kml_path: Optional[str] = None
    arquivo_shapefile_path: Optional[str] = None
    
    # Metadados
    coordenadas_origem: Optional[str] = Field(
        None, 
        description="'gps', 'mapa', 'kmz', 'manual'"
    )
    
    def calcular_area_ha(self):
        """Converte m² para hectares"""
        if self.area_m2:
            self.area_ha = self.area_m2 / 10000
    
    class Config:
        json_schema_extra = {
            "example": {
                "latitude": -23.5505199,
                "longitude": -46.6333094,
                "area_m2": 5000,
                "coordenadas_origem": "gps"
            }
        }


class TanqueModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Tanque de Armazenamento
    Usado em: Passivo, NR13, Licenciamento
    """
    produto: Optional[str] = Field(None, max_length=100)
    capacidade_litros: Optional[int] = Field(None, gt=0)
    tipo_tanque: Optional[str] = None  # 'subterraneo', 'aereo', etc
    material: Optional[str] = None  # 'aco', 'fibra', 'plastico'
    ano_instalacao: Optional[int] = Field(None, ge=1950, le=2030)
    ano_fabricacao: Optional[int] = Field(None, ge=1950, le=2030)
    
    # NR13 específico
    numero_serie: Optional[str] = None
    fabricante: Optional[str] = None
    pressao_trabalho: Optional[float] = None
    temperatura_trabalho: Optional[float] = None
    ultima_inspecao: Optional[date] = None
    proxima_inspecao: Optional[date] = None
    
    # Proteções
    tem_deteccao_vazamento: Optional[bool] = False
    sistema_deteccao: Optional[str] = None
    tem_contencao: Optional[bool] = False
    tipo_contencao: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "produto": "Diesel S10",
                "capacidade_litros": 15000,
                "tipo_tanque": "subterraneo_parede_dupla",
                "ano_instalacao": 2015
            }
        }


class DocumentoModel(BaseModel):
    """
    ✅ BLOCO REUTILIZÁVEL - Documento/Arquivo Anexado
    Usado em: Todas as entrevistas
    """
    nome_original: str
    tipo: str  # 'foto', 'pdf', 'kmz', 'xlsx', etc
    mime_type: Optional[str] = None
    tamanho_bytes: Optional[int] = None
    descricao: Optional[str] = None
    categoria: Optional[str] = None  # 'licenca', 'foto', 'laudo', etc
    
    # Após upload para MinIO
    minio_bucket: Optional[str] = None
    minio_path: Optional[str] = None
    minio_url: Optional[str] = None
    
    # Metadados
    data_upload: Optional[datetime] = Field(default_factory=datetime.now)
    hash_md5: Optional[str] = None


# =============================================================================
# MODELOS DE ENTREVISTAS COMPLETAS
# =============================================================================

class PassivoAmbientalPayload(BaseModel):
    """
    Payload completo da entrevista de Passivo Ambiental.
    Composto por vários blocos reutilizáveis.
    """
    # Metadados da entrevista
    tipo_entrevista: TipoRelatorio = TipoRelatorio.PASSIVO_AMBIENTAL
    protocolo: str
    versao_entrevista: str = "3.0.0"
    data_inicio: Optional[datetime] = None
    data_conclusao: Optional[datetime] = None
    tempo_preenchimento_minutos: Optional[int] = None
    
    # BLOCOS REUTILIZÁVEIS
    dados_cadastrais: Optional[DadosCadastraisModel] = None
    contato: Optional[ContatoModel] = None
    endereco: Optional[EnderecoModel] = None
    localizacao: Optional[LocalizacaoModel] = None
    
    # Dados específicos do Passivo
    projeto: Optional[Dict[str, Any]] = None
    infraestrutura: Optional[Dict[str, Any]] = None
    tanques: Optional[List[TanqueModel]] = []
    historico: Optional[Dict[str, Any]] = None
    monitoramento: Optional[Dict[str, Any]] = None
    
    # Documentos
    documentos: Optional[List[DocumentoModel]] = []
    
    # Status
    percentual_preenchimento: Optional[float] = Field(None, ge=0, le=100)
    campos_criticos_faltantes: Optional[List[str]] = []
    
    class Config:
        json_schema_extra = {
            "example": {
                "tipo_entrevista": "passivo_ambiental",
                "protocolo": "PA-20241224-153045",
                "dados_cadastrais": {
                    "cnpj": "12345678000190",
                    "razao_social": "POSTO EXEMPLO LTDA"
                },
                "tanques": [
                    {
                        "produto": "Diesel S10",
                        "capacidade_litros": 15000
                    }
                ]
            }
        }


class PGRSPayload(BaseModel):
    """
    Payload completo da entrevista de PGRS.
    Reutiliza blocos: dados_cadastrais, contato, endereco, localizacao.
    """
    tipo_entrevista: TipoRelatorio = TipoRelatorio.PGRS
    protocolo: str
    versao_entrevista: str = "1.0.0"
    
    # BLOCOS REUTILIZÁVEIS (mesmos do Passivo)
    dados_cadastrais: Optional[DadosCadastraisModel] = None
    contato: Optional[ContatoModel] = None
    endereco: Optional[EnderecoModel] = None
    localizacao: Optional[LocalizacaoModel] = None
    
    # Dados específicos do PGRS
    atividades: Optional[List[str]] = []
    residuos_gerados: Optional[Dict[str, Any]] = None
    destinacao_residuos: Optional[Dict[str, Any]] = None
    responsavel_tecnico: Optional[Dict[str, Any]] = None
    
    # Documentos
    documentos: Optional[List[DocumentoModel]] = []


class NR13Payload(BaseModel):
    """
    Payload completo da entrevista de NR13.
    Reutiliza blocos: dados_cadastrais, contato, endereco, tanques.
    """
    tipo_entrevista: TipoRelatorio = TipoRelatorio.NR13
    protocolo: str
    versao_entrevista: str = "1.0.0"
    
    # BLOCOS REUTILIZÁVEIS
    dados_cadastrais: Optional[DadosCadastraisModel] = None
    contato: Optional[ContatoModel] = None
    endereco: Optional[EnderecoModel] = None
    
    # Tanques/Vasos (NR13 tem campos específicos)
    equipamentos: Optional[List[TanqueModel]] = []
    
    # Dados específicos NR13
    responsavel_tecnico: Optional[Dict[str, Any]] = None
    plano_inspecao: Optional[Dict[str, Any]] = None
    historico_inspecoes: Optional[List[Dict[str, Any]]] = []
    
    # Documentos
    documentos: Optional[List[DocumentoModel]] = []


# =============================================================================
# MODELO UNIFICADO DE RESPOSTA
# =============================================================================

class RespostaAPI(BaseModel):
    """Resposta padronizada da API após ingestão"""
    sucesso: bool
    protocolo: str
    id_avaliacao: Optional[str] = None
    mensagem: str
    timestamp: datetime = Field(default_factory=datetime.now)
    
    # Validação
    campos_criticos_faltantes: Optional[List[str]] = []
    campos_importantes_faltantes: Optional[List[str]] = []
    avisos: Optional[List[str]] = []
    
    # URLs
    webhook_status: Optional[str] = None
    url_acompanhamento: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "sucesso": True,
                "protocolo": "PA-20241224-153045",
                "id_avaliacao": "550e8400-e29b-41d4-a716-446655440000",
                "mensagem": "Dados recebidos e validados com sucesso"
            }
        }
