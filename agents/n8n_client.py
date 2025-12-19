"""
n8n Client (DUMMY)
Trigger webhooks do n8n para notificações
"""

def trigger_started(project_id):
    return {"message": "Trigger n8n started - TODO"}

def trigger_completed(project_id):
    return {"message": "Trigger n8n completed - TODO"}

print("Hello from n8n_client.py!")
