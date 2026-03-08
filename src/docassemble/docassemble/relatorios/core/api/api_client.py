# /opt/stackdevops/src/docassemble/docassemble/relatorios/core/api_client.py

import os
import requests
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class DocassembleAPIClient:
    """
    Client responsável por enviar submissões do Docassemble
    para a API principal (FastAPI).
    """

    def __init__(self, base_url: str | None = None):
        # Prioridade:
        # 1. base_url passado explicitamente
        # 2. variável de ambiente APIURL
        # 3. fallback seguro para ambiente docker
        self.endpoint = (
            base_url
            or os.getenv("APIURL")
            or "http://api:8000/api/v1/docassemble/submissions"
        )

        self.timeout = 30

    def enviar_para_api(self, tipo_relatorio, protocolo, dados, versao):
        """
        Envia os dados consolidados da entrevista para a API.

        Retorna sempre um dicionário padronizado para consumo no YAML.
        """

        payload = {
            "tipo_relatorio": tipo_relatorio,
            "protocolo": protocolo,
            "versao": versao,
            "timestamp": datetime.utcnow().isoformat(),
            "dados": dados,
        }

        try:
            logger.info(
                f"[DocassembleAPIClient] Enviando protocolo {protocolo} para {self.endpoint}"
            )

            response = requests.post(
                self.endpoint,
                json=payload,
                timeout=self.timeout,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": f"Docassemble-Relatorios/{versao}",
                },
            )

            response.raise_for_status()
            result = response.json()

            sucesso = result.get("success") is True

            return {
                "sucesso": sucesso,
                "codigo_http": response.status_code,
                "resposta_api": result,
                "submission_id": result.get("submission_id"),
                "job_id": result.get("job_id"),
                "status": result.get("status"),
            }

        except requests.exceptions.Timeout as e:
            logger.error("Timeout ao enviar dados para a API", exc_info=True)
            return {
                "sucesso": False,
                "erro": "TIMEOUT",
                "mensagem": "Timeout na comunicação com a API",
                "detalhes": str(e),
            }

        except requests.exceptions.ConnectionError as e:
            logger.error("Erro de conexão com a API", exc_info=True)
            return {
                "sucesso": False,
                "erro": "CONNECTION_ERROR",
                "mensagem": "Não foi possível conectar à API",
                "detalhes": str(e),
            }

        except requests.exceptions.RequestException as e:
            logger.error("Erro HTTP ao enviar dados", exc_info=True)
            return {
                "sucesso": False,
                "erro": "HTTP_ERROR",
                "mensagem": "Erro HTTP na comunicação com a API",
                "codigo_http": getattr(e.response, "status_code", None),
                "detalhes": str(e),
            }

        except Exception as e:
            logger.error("Erro inesperado no envio para API", exc_info=True)
            return {
                "sucesso": False,
                "erro": "UNEXPECTED_ERROR",
                "mensagem": "Erro inesperado no envio",
                "detalhes": str(e),
            }


# -------------------------------------------------------------------------
# Função de conveniência para uso direto no YAML
# -------------------------------------------------------------------------

def enviar_para_api(tipo_relatorio, protocolo, dados, versao):
    client = DocassembleAPIClient()
    return client.enviar_para_api(tipo_relatorio, protocolo, dados, versao)
