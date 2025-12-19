# Sistema de Geração de Documentos LaTeX - Fase 1

Sistema simplificado para geração de documentos LaTeX usando FastAPI, PostgreSQL e Nginx como reverse proxy.

## 📋 Pré-requisitos

- **Docker** (versão 20.10 ou superior)
- **Docker Compose** (versão 2.0 ou superior)

### Verificar instalação:
```bash
docker --version
docker compose version
```

## 🚀 Como Rodar o Projeto

### Passo 1: Criar arquivo `.env` (opcional)

Crie um arquivo `.env` na raiz do projeto se quiser personalizar as configurações:

```env
# Timezone
TZ=America/Sao_Paulo

# PostgreSQL
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=projeto_db
POSTGRES_PORT=5432

# FastAPI
LOG_LEVEL=INFO
```

**Nota:** Se não criar o `.env`, os valores padrão serão usados.

### Passo 2: Iniciar os serviços

```bash
# Primeira vez (com build)
docker compose up -d --build

# Próximas vezes (sem build)
docker compose up -d
```

### Passo 3: Verificar status

```bash
docker compose ps
```

## 🌐 URLs de Acesso

Após iniciar os serviços:

- **API (via Nginx)**: http://localhost
- **API Direta**: http://localhost:8000 (não exposta externamente, apenas via Nginx)
- **Documentação Swagger**: http://localhost/docs
- **Documentação ReDoc**: http://localhost/redoc
- **PostgreSQL**: localhost:5432
  - Usuário: `admin`
  - Senha: `admin`
  - Database: `projeto_db`

## 📝 Comandos Úteis

### Ver logs
```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f api
docker compose logs -f postgres
docker compose logs -f nginx
```

### Parar serviços
```bash
docker compose stop
```

### Parar e remover containers
```bash
docker compose down
```

### Reiniciar um serviço específico
```bash
docker compose restart api
```

### Reconstruir um serviço
```bash
docker compose up -d --build api
```

### Acessar shell de um container
```bash
docker compose exec api bash
docker compose exec postgres psql -U admin -d projeto_db
```

## 📦 Estrutura do Projeto

```
.
├── agents/              # Aplicação FastAPI
│   ├── main.py         # Ponto de entrada FastAPI
│   ├── requirements.txt # Dependências Python
│   └── Dockerfile      # Imagem Docker da API
├── nginx/              # Configuração do Nginx
│   └── nginx.conf      # Configuração do reverse proxy
├── sql/                # Scripts SQL
│   └── init.sql        # Script de inicialização do banco
├── templates/          # Templates LaTeX
├── docker-compose.yml  # Configuração dos serviços
└── .env               # Variáveis de ambiente (opcional)
```

## 🔧 Arquitetura

### Serviços

1. **PostgreSQL** (porta 5432)
   - Banco de dados principal
   - Schema inicial criado automaticamente via `sql/init.sql`

2. **FastAPI** (porta 8000 - interna)
   - API backend
   - Acessível apenas via Nginx (rede interna)

3. **Nginx** (porta 80)
   - Reverse proxy
   - Roteia requisições para FastAPI
   - Compressão gzip habilitada
   - Timeout configurado para 60s

### Rede Interna

Todos os serviços estão na rede `projeto-network` e se comunicam internamente:
- Nginx → FastAPI: `http://api:8000`
- FastAPI → PostgreSQL: `postgres:5432`

## 🆘 Troubleshooting

### Erro: "Cannot connect to Docker daemon"
- Certifique-se de que o Docker Desktop está rodando (Windows/Mac)
- No Linux, verifique se o serviço Docker está ativo: `sudo systemctl status docker`

### Erro: "Port already in use"
- Verifique se alguma porta (80, 5432) já está em uso
- Altere as portas no `docker-compose.yml` se necessário

### Serviços não iniciam
```bash
# Ver logs detalhados
docker compose logs

# Verificar status
docker compose ps

# Health check manual do PostgreSQL
docker compose exec postgres pg_isready -U admin
```

### Limpar tudo e começar do zero
```bash
# CUIDADO: Isso apaga todos os dados!
docker compose down -v
rm -rf data/*
docker compose up -d --build
```

## 📚 Próximos Passos (Fase 1)

- [ ] Criar endpoint de validação com query no banco
- [ ] Implementar renderização de templates LaTeX com Jinja2
- [ ] Criar template LaTeX de exemplo
- [ ] Integrar compilação TexLive com o endpoint FastAPI
