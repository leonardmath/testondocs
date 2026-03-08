import requests

def submit_to_api(payload):
    """Função interna para envio ao endpoint"""
    try:
        response = requests.post(
            "http://api:8000/api/v1/submissions",
            json=payload,
            timeout=10
        )
        return response.json()
    except Exception as e:
        return {"sucesso": False, "erro": str(e)}

def enviar_para_api(*, tipo_relatorio, protocolo, dados, versao):
    """
    Função pública esperada pelo Docassemble/YAML.
    Constrói o payload e delega ao submit_to_api.
    """
    payload = {
        "tipo_relatorio": tipo_relatorio,
        "protocolo": protocolo,
        "versao": versao,
        "dados": dados,
    }

    resposta = submit_to_api(payload)

    # normalização de retorno
    if isinstance(resposta, dict) and "error" not in resposta:
        return {"sucesso": True, "resposta": resposta}

    return {"sucesso": False, "erro": resposta}
