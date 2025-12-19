#!/bin/bash
# ============================================================================
# manager.sh v3.0 - Docker Compose Manager (FIXED)
# ============================================================================
# Gerenciador completo para o projeto LaTeX Document Generator
# Corrigido: leitura do .env agora funciona corretamente
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Helper functions
print_header() { 
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ $1${NC}"; }

confirm() {
    read -r -p "$(echo -e ${YELLOW}"$1 [y/N]: "${NC})" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ============================================================================
# BASIC OPERATIONS
# ============================================================================

check_prerequisites() {
    print_header "Verificando pré-requisitos"
    
    if ! command -v docker &>/dev/null; then
        print_error "Docker não encontrado"
        return 1
    fi
    
    if ! docker compose version &>/dev/null; then
        print_error "Docker Compose não disponível"
        return 1
    fi
    
    if [ ! -f .env ]; then
        print_warning ".env não encontrado"
        if [ -f .env.example ]; then
            if confirm "Copiar .env.example para .env?"; then
                cp .env.example .env
                print_success ".env criado"
                print_warning "EDITE O .env COM SUAS CREDENCIAIS ANTES DE CONTINUAR!"
                read -p "Pressione Enter após editar o .env..."
            fi
        fi
    fi
    
    print_success "Docker e Docker Compose OK"
    print_info "Docker Compose: $(docker compose version --short)"
    return 0
}

start_services() {
    print_header "Iniciando serviços"
    
    if [ "${1:-}" = "--build" ]; then
        print_info "Iniciando com rebuild..."
        docker compose up -d --build
    else
        docker compose up -d
    fi
    
    print_success "Comando docker compose up executado"
    sleep 3
    show_status
}

stop_services() {
    print_header "Parando serviços"
    docker compose stop
    print_success "Serviços parados"
}

restart_services() {
    print_header "Reiniciando serviços"
    docker compose restart
    print_success "Serviços reiniciados"
    show_status
}

down_services() {
    print_header "Parando e removendo containers"
    docker compose down
    print_success "Containers removidos"
}

show_status() {
    print_header "Status dos Serviços"
    docker compose ps
}

show_logs() {
    print_header "Logs dos Serviços"
    echo "Serviços disponíveis:"
    docker compose ps --services
    echo ""
    read -r -p "Digite o nome do serviço (ou 'all' para todos): " svc
    
    if [ "$svc" = "all" ]; then
        docker compose logs -f --tail=100
    else
        docker compose logs -f --tail=100 "$svc"
    fi
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

health_check() {
    print_header "Verificação de Saúde dos Serviços"
    
    # Postgres
    print_info "Verificando PostgreSQL..."
    if docker compose exec -T postgres pg_isready -U admin -d projeto_db >/dev/null 2>&1; then
        print_success "PostgreSQL: OK"
    else
        print_error "PostgreSQL: Falhou"
    fi
    
    # MinIO
    print_info "Verificando MinIO..."
    if docker compose ps minio | grep -q "Up"; then
        print_success "MinIO: Rodando"
    else
        print_error "MinIO: Não está rodando"
    fi
    
    # NocoDB
    print_info "Verificando NocoDB..."
    if docker compose ps nocodb | grep -q "Up"; then
        print_success "NocoDB: Rodando"
    else
        print_warning "NocoDB: Não está rodando"
    fi
    
    # n8n
    print_info "Verificando n8n..."
    if docker compose ps n8n | grep -q "Up"; then
        print_success "n8n: Rodando"
    else
        print_warning "n8n: Não está rodando"
    fi
    
    # FastAPI/Agents
    print_info "Verificando FastAPI (agents)..."
    if docker compose ps agents | grep -q "Up"; then
        print_success "FastAPI: Rodando"
        # Tentar curl
        if docker compose exec -T agents curl -fsS http://localhost:8000/ >/dev/null 2>&1; then
            print_success "FastAPI: Respondendo HTTP"
        else
            print_warning "FastAPI: Container up mas não responde HTTP"
        fi
    else
        print_error "FastAPI: Não está rodando"
    fi
    
    # Dozzle
    print_info "Verificando Dozzle..."
    if docker compose ps dozzle | grep -q "Up"; then
        print_success "Dozzle: Rodando"
    else
        print_warning "Dozzle: Não está rodando"
    fi
    
    print_header "URLs de Acesso"
    echo -e "FastAPI:  ${BLUE}http://localhost:8000${NC}"
    echo -e "NocoDB:   ${BLUE}http://localhost:8080${NC}"
    echo -e "n8n:      ${BLUE}http://localhost:5678${NC} (admin/admin)"
    echo -e "MinIO:    ${BLUE}http://localhost:9001${NC} (admin/admin)"
    echo -e "Dozzle:   ${BLUE}http://localhost:8888${NC}"
    echo -e "Postgres: ${BLUE}localhost:5432${NC} (admin/admin)"
}

# ============================================================================
# DATABASE OPERATIONS
# ============================================================================

init_databases() {
    print_header "Inicializando Databases"
    
    if ! docker compose ps postgres | grep -q "Up"; then
        print_error "PostgreSQL não está rodando. Inicie os serviços primeiro."
        return 1
    fi
    
    print_info "Criando database 'nocodb'..."
    if docker compose exec -T postgres psql -U admin -d postgres -c "CREATE DATABASE nocodb;" 2>/dev/null; then
        print_success "Database 'nocodb' criado"
    else
        print_warning "Database 'nocodb' já existe ou falhou"
    fi
    
    print_info "Criando database 'n8n'..."
    if docker compose exec -T postgres psql -U admin -d postgres -c "CREATE DATABASE n8n;" 2>/dev/null; then
        print_success "Database 'n8n' criado"
    else
        print_warning "Database 'n8n' já existe ou falhou"
    fi
    
    print_info "Verificando schema do projeto_db..."
    docker compose exec -T postgres psql -U admin -d projeto_db -c "\dt" 2>/dev/null || print_warning "Tabelas ainda não criadas (executar init.sql)"
    
    print_success "Inicialização de databases concluída"
}

run_sql_script() {
    print_header "Executar Script SQL"
    
    if ! docker compose ps postgres | grep -q "Up"; then
        print_error "PostgreSQL não está rodando"
        return 1
    fi
    
    if [ ! -f sql/init.sql ]; then
        print_error "Arquivo sql/init.sql não encontrado"
        return 1
    fi
    
    print_info "Executando sql/init.sql no database projeto_db..."
    docker compose exec -T postgres psql -U admin -d projeto_db < sql/init.sql
    print_success "Script SQL executado"
}

postgres_shell() {
    print_header "Shell PostgreSQL"
    
    if ! docker compose ps postgres | grep -q "Up"; then
        print_error "PostgreSQL não está rodando"
        return 1
    fi
    
    print_info "Conectando ao PostgreSQL..."
    docker compose exec postgres psql -U admin -d projeto_db
}

# ============================================================================
# MINIO OPERATIONS
# ============================================================================

init_minio_buckets() {
    print_header "Inicializar Buckets do MinIO"
    
    if ! docker compose ps minio | grep -q "Up"; then
        print_error "MinIO não está rodando"
        return 1
    fi
    
    print_info "Aguardando MinIO ficar pronto..."
    sleep 5
    
    # Criar buckets usando MinIO client dentro do container
    print_info "Criando bucket 'projects'..."
    docker compose exec -T minio sh -c "
        mc alias set local http://localhost:9000 admin admin 2>/dev/null || true
        mc mb local/projects 2>/dev/null || echo 'Bucket já existe'
        mc anonymous set download local/projects
    " && print_success "Bucket 'projects' OK"
    
    print_info "Criando bucket 'assets'..."
    docker compose exec -T minio sh -c "
        mc mb local/assets 2>/dev/null || echo 'Bucket já existe'
    " && print_success "Bucket 'assets' OK"
    
    print_info "Criando bucket 'outputs'..."
    docker compose exec -T minio sh -c "
        mc mb local/outputs 2>/dev/null || echo 'Bucket já existe'
    " && print_success "Bucket 'outputs' OK"
    
    print_success "Buckets MinIO configurados"
}

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

backup_postgres() {
    print_header "Backup PostgreSQL"
    
    mkdir -p ./backups/postgres
    
    if ! docker compose ps postgres | grep -q "Up"; then
        print_error "PostgreSQL não está rodando"
        return 1
    fi
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="./backups/postgres/backup_${TIMESTAMP}.sql"
    
    print_info "Fazendo backup de todos os databases..."
    docker compose exec -T postgres pg_dumpall -U admin > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        print_success "Backup criado: $BACKUP_FILE ($SIZE)"
        
        # Compactar
        gzip "$BACKUP_FILE"
        print_success "Backup compactado: ${BACKUP_FILE}.gz"
    else
        print_error "Falha ao criar backup"
    fi
}

backup_minio() {
    print_header "Backup MinIO"
    
    mkdir -p ./backups/minio
    
    if ! docker compose ps minio | grep -q "Up"; then
        print_error "MinIO não está rodando"
        return 1
    fi
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="./backups/minio/backup_${TIMESTAMP}"
    
    print_info "Copiando dados do MinIO..."
    mkdir -p "$BACKUP_DIR"
    docker compose cp minio:/data "$BACKUP_DIR/"
    
    if [ -d "$BACKUP_DIR" ]; then
        print_success "Backup MinIO criado: $BACKUP_DIR"
        
        # Compactar
        tar -czf "${BACKUP_DIR}.tar.gz" -C ./backups/minio "backup_${TIMESTAMP}"
        rm -rf "$BACKUP_DIR"
        print_success "Backup compactado: ${BACKUP_DIR}.tar.gz"
    else
        print_error "Falha ao criar backup"
    fi
}

full_backup() {
    print_header "Backup Completo"
    backup_postgres
    echo ""
    backup_minio
    print_success "Backup completo finalizado"
}

# ============================================================================
# MAINTENANCE
# ============================================================================

clean_volumes() {
    print_header "Limpar Volumes (CUIDADO!)"
    
    print_error "Esta operação VAI DELETAR TODOS OS DADOS!"
    if ! confirm "Tem certeza que deseja limpar os volumes?"; then
        print_info "Operação cancelada"
        return 0
    fi
    
    if ! confirm "ÚLTIMA CHANCE! Confirma a exclusão de todos os dados?"; then
        print_info "Operação cancelada"
        return 0
    fi
    
    print_info "Parando containers..."
    docker compose down
    
    print_info "Removendo volumes..."
    docker volume rm engeteston_postgres_data engeteston_minio_data engeteston_n8n_data 2>/dev/null || true
    
    print_info "Limpando diretórios..."
    rm -rf data/postgres/* data/minio/* data/n8n/* data/nocodb/*
    
    print_success "Volumes limpos"
}

rebuild_service() {
    print_header "Rebuild de Serviço Específico"
    
    echo "Serviços disponíveis:"
    docker compose ps --services
    echo ""
    read -r -p "Digite o nome do serviço: " svc
    
    if docker compose ps --services | grep -q "^${svc}$"; then
        print_info "Reconstruindo $svc..."
        docker compose up -d --build "$svc"
        print_success "Serviço $svc reconstruído"
    else
        print_error "Serviço não encontrado"
    fi
}

enter_container() {
    print_header "Entrar em Container"
    
    echo "Containers disponíveis:"
    docker compose ps --format "{{.Service}}"
    echo ""
    read -r -p "Digite o nome do container: " container
    
    if docker compose ps | grep -q "$container"; then
        print_info "Acessando $container..."
        docker compose exec "$container" sh -c 'if command -v bash >/dev/null 2>&1; then bash; else sh; fi'
    else
        print_error "Container não encontrado ou não está rodando"
    fi
}

view_config() {
    print_header "Visualizar Configuração Atual"
    print_info "Mostrando docker-compose com variáveis resolvidas..."
    echo ""
    docker compose config
}

# ============================================================================
# FRESH SETUP
# ============================================================================

fresh_setup() {
    print_header "Setup Completo (Fresh Install)"
    
    check_prerequisites
    
    print_info "Limpando containers antigos..."
    docker compose down 2>/dev/null || true
    
    print_info "Limpando dados antigos..."
    rm -rf data/postgres/* data/minio/* data/n8n/* data/nocodb/* 2>/dev/null || true
    
    print_info "Criando diretórios..."
    mkdir -p data/postgres data/minio data/n8n data/nocodb backups/postgres backups/minio
    
    print_info "Subindo PostgreSQL..."
    docker compose up -d postgres
    sleep 15
    
    print_info "Inicializando databases..."
    init_databases
    
    print_info "Executando init.sql..."
    run_sql_script
    
    print_info "Subindo demais serviços..."
    docker compose up -d
    sleep 10
    
    print_info "Inicializando buckets MinIO..."
    init_minio_buckets
    
    print_success "Setup completo finalizado!"
    echo ""
    health_check
}

# ============================================================================
# MENU
# ============================================================================

show_menu() {
    clear
    print_header "LaTeX Generator - Manager v3.0"
    cat << 'EOF'
BÁSICO:
  1)  Fresh Setup (instalação completa do zero)
  2)  Iniciar todos os serviços
  3)  Iniciar com rebuild
  4)  Parar serviços
  5)  Reiniciar serviços
  6)  Parar e remover containers
  7)  Status dos serviços
  8)  Ver logs

SAÚDE:
  9)  Health check completo
  10) Visualizar configuração atual

DATABASE:
  11) Inicializar databases (nocodb, n8n)
  12) Executar sql/init.sql
  13) Shell PostgreSQL

MINIO:
  14) Inicializar buckets MinIO

BACKUP:
  15) Backup PostgreSQL
  16) Backup MinIO
  17) Backup completo

MANUTENÇÃO:
  18) Rebuild serviço específico
  19) Entrar em container
  20) Limpar volumes (DELETA TUDO!)

  0)  Sair

EOF
}

# ============================================================================
# MAIN MENU LOOP
# ============================================================================

main_menu() {
    while true; do
        show_menu
        read -r -p "Escolha uma opção: " choice
        echo ""
        
        case "$choice" in
            1)  fresh_setup ;;
            2)  start_services ;;
            3)  start_services --build ;;
            4)  stop_services ;;
            5)  restart_services ;;
            6)  down_services ;;
            7)  show_status ;;
            8)  show_logs ;;
            9)  health_check ;;
            10) view_config ;;
            11) init_databases ;;
            12) run_sql_script ;;
            13) postgres_shell ;;
            14) init_minio_buckets ;;
            15) backup_postgres ;;
            16) backup_minio ;;
            17) full_backup ;;
            18) rebuild_service ;;
            19) enter_container ;;
            20) clean_volumes ;;
            0)  print_info "Saindo..."; exit 0 ;;
            *)  print_error "Opção inválida" ;;
        esac
        
        echo ""
        read -r -p "Pressione Enter para continuar..."
    done
}

# ============================================================================
# RUN
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi