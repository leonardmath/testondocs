-- ============================================================================
-- Schema Inicial - Sistema de Laudos Ambientais
-- ============================================================================
-- Este script cria as tabelas para gestão de laudos ambientais com FastAPI + NocoDB
-- ============================================================================

-- Conectar ao banco principal
\c projeto_db;

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Para criptografia se necessário

-- ============================================================================
-- TABELA PRINCIPAL: empresas
-- ============================================================================
CREATE TABLE IF NOT EXISTS empresas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identificação básica
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    nome_fantasia VARCHAR(255),
    
    -- Informações cadastrais
    data_abertura DATE,
    porte VARCHAR(20),
    natureza_juridica VARCHAR(100),
    situacao_cadastral VARCHAR(50),
    
    -- Contato
    email VARCHAR(255),
    telefone VARCHAR(50),
    responsavel_tecnico VARCHAR(255),
    
    -- Endereço (simplificado)
    endereco_logradouro VARCHAR(255),
    endereco_numero VARCHAR(20),
    endereco_bairro VARCHAR(100),
    endereco_municipio VARCHAR(100),
    endereco_uf CHAR(2),
    endereco_cep VARCHAR(10),
    
    -- Metadados
    status VARCHAR(50) DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'suspenso')),
    origem_dados VARCHAR(100),
    observacoes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para empresas
CREATE INDEX idx_empresas_cnpj ON empresas(cnpj);
CREATE INDEX idx_empresas_razao_social ON empresas(razao_social);
CREATE INDEX idx_empresas_endereco_municipio ON empresas(endereco_municipio);
CREATE INDEX idx_empresas_status ON empresas(status);

-- ============================================================================
-- TABELA: projetos
-- ============================================================================
CREATE TABLE IF NOT EXISTS projetos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identificação
    codigo_projeto VARCHAR(100) UNIQUE NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    
    -- Relacionamentos
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    
    -- Metadados do projeto
    tipo_projeto VARCHAR(100) NOT NULL, -- 'passivo_ambiental', 'pgrs', 'emissoes', 'ruido', 'outros'
    status_projeto VARCHAR(50) DEFAULT 'planejamento' 
        CHECK (status_projeto IN ('planejamento', 'andamento', 'concluido', 'cancelado', 'suspenso')),
    
    -- Datas importantes
    data_inicio DATE,
    data_prevista_entrega DATE,
    data_conclusao DATE,
    
    -- Responsáveis
    responsavel_tecnico VARCHAR(255),
    coordenador_projeto VARCHAR(255),
    
    -- Orçamento
    valor_orcado DECIMAL(15,2),
    valor_executado DECIMAL(15,2),
    
    -- Configurações do workflow
    workflow_config JSONB,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- NocoDB Sync
    nocodb_record_id VARCHAR(100),
    last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Índices para projetos
CREATE INDEX idx_projetos_empresa_id ON projetos(empresa_id);
CREATE INDEX idx_projetos_tipo ON projetos(tipo_projeto);
CREATE INDEX idx_projetos_status ON projetos(status_projeto);
CREATE INDEX idx_projetos_codigo ON projetos(codigo_projeto);

-- ============================================================================
-- TABELA: tarefas (workflow)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tarefas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identificação
    codigo_tarefa VARCHAR(100),
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    
    -- Relacionamentos
    projeto_id UUID NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
    tarefa_pai_id UUID REFERENCES tarefas(id) ON DELETE CASCADE,
    
    -- Metadados da tarefa
    tipo_tarefa VARCHAR(100) NOT NULL, -- 'coleta_campo', 'analise_lab', 'redacao', 'revisao', 'aprovacao'
    etapa_workflow VARCHAR(100) NOT NULL, -- 'diagnostico', 'prognostico', 'validacao'
    fase_projeto VARCHAR(100), -- 'inicial', 'intermediaria', 'final'
    
    -- Status e prioridade
    status VARCHAR(50) DEFAULT 'pendente' 
        CHECK (status IN ('pendente', 'em_andamento', 'concluida', 'atrasada', 'cancelada', 'bloqueada')),
    prioridade INTEGER DEFAULT 3 CHECK (prioridade BETWEEN 1 AND 5), -- 1 = máxima, 5 = mínima
    
    -- Datas
    data_inicio_prevista DATE,
    data_conclusao_prevista DATE,
    data_inicio_real TIMESTAMP WITH TIME ZONE,
    data_conclusao_real TIMESTAMP WITH TIME ZONE,
    
    -- Responsáveis
    responsavel_id UUID, -- Poderia referenciar tabela de usuários
    responsavel_nome VARCHAR(255),
    
    -- Progresso
    progresso INTEGER DEFAULT 0 CHECK (progresso BETWEEN 0 AND 100),
    tempo_estimado_horas DECIMAL(5,2),
    tempo_executado_horas DECIMAL(5,2),
    
    -- Dependências
    dependencias UUID[], -- IDs de tarefas dependentes
    bloqueadores TEXT[], -- Motivos de bloqueio
    
    -- Metadados
    tags TEXT[],
    anexos_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- NocoDB Sync
    nocodb_record_id VARCHAR(100)
);

-- Índices para tarefas
CREATE INDEX idx_tarefas_projeto_id ON tarefas(projeto_id);
CREATE INDEX idx_tarefas_status ON tarefas(status);
CREATE INDEX idx_tarefas_tipo ON tarefas(tipo_tarefa);
CREATE INDEX idx_tarefas_etapa ON tarefas(etapa_workflow);
CREATE INDEX idx_tarefas_responsavel ON tarefas(responsavel_nome);
CREATE INDEX idx_tarefas_data_conclusao ON tarefas(data_conclusao_prevista);

-- ============================================================================
-- TABELAS JSONB PARA DADOS TÉCNICOS
-- ============================================================================

-- TABELA: dados_diagnostico (dados de entrada/coleta)
CREATE TABLE IF NOT EXISTS dados_diagnostico (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relacionamentos
    projeto_id UUID NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
    tarefa_id UUID REFERENCES tarefas(id) ON DELETE SET NULL,
    
    -- Metadados do diagnóstico
    tipo_laudo VARCHAR(100) NOT NULL CHECK (tipo_laudo IN (
        'passivo_ambiental', 'pgrs', 'emissoes_atmosfericas', 
        'laudo_ruido', 'qualidade_agua', 'solo_contaminado',
        'estudo_impacto', 'outros'
    )),
    
    -- Dados estruturados por tipo de laudo
    dados_coleta JSONB NOT NULL, -- Dados de campo/coleta
    dados_analise JSONB, -- Resultados de análises laboratoriais
    
    -- Metadados técnicos
    metodo_coleta VARCHAR(255),
    equipamentos_utilizados TEXT[],
    normas_referencia TEXT[],
    
    -- Validação
    valido BOOLEAN DEFAULT TRUE,
    observacoes_validacao TEXT,
    validado_por VARCHAR(255),
    data_validacao TIMESTAMP WITH TIME ZONE,
    
    -- Localização
    coordenadas_geograficas JSONB, -- {lat: xx, lng: xx, pontos: []}
    endereco_coleta VARCHAR(500),
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para dados_diagnostico
CREATE INDEX idx_diagnostico_projeto_id ON dados_diagnostico(projeto_id);
CREATE INDEX idx_diagnostico_tipo_laudo ON dados_diagnostico(tipo_laudo);
CREATE INDEX idx_diagnostico_valido ON dados_diagnostico(valido);
CREATE INDEX idx_diagnostico_json_coleta ON dados_diagnostico USING GIN (dados_coleta);
CREATE INDEX idx_diagnostico_json_analise ON dados_diagnostico USING GIN (dados_analise);

-- TABELA: dados_prognostico (resultados/recomendações)
CREATE TABLE IF NOT EXISTS dados_prognostico (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relacionamentos
    projeto_id UUID NOT NULL REFERENCES projetos(id) ON DELETE CASCADE,
    diagnostico_id UUID REFERENCES dados_diagnostico(id) ON DELETE CASCADE,
    tarefa_id UUID REFERENCES tarefas(id) ON DELETE SET NULL,
    
    -- Metadados do prognóstico
    tipo_prognostico VARCHAR(100) NOT NULL CHECK (tipo_prognostico IN (
        'analise_risco', 'recomendacoes', 'plano_acao',
        'modelagem', 'projecao', 'relatorio_conclusivo'
    )),
    
    -- Dados estruturados
    resultados JSONB NOT NULL, -- Resultados/modelagem
    recomendacoes JSONB, -- Recomendações e ações
    
    -- Classificação
    nivel_risco VARCHAR(50), -- 'baixo', 'medio', 'alto', 'critico'
    nivel_prioridade INTEGER CHECK (nivel_prioridade BETWEEN 1 AND 5),
    
    -- Impactos
    impacto_ambiental TEXT,
    impacto_economico DECIMAL(15,2),
    prazo_execucao_meses INTEGER,
    
    -- Conformidade
    atendimento_legislacao BOOLEAN,
    legislacao_aplicavel TEXT[],
    
    -- Metadados
    aprovado BOOLEAN DEFAULT FALSE,
    aprovado_por VARCHAR(255),
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para dados_prognostico
CREATE INDEX idx_prognostico_projeto_id ON dados_prognostico(projeto_id);
CREATE INDEX idx_prognostico_diagnostico_id ON dados_prognostico(diagnostico_id);
CREATE INDEX idx_prognostico_tipo ON dados_prognostico(tipo_prognostico);
CREATE INDEX idx_prognostico_nivel_risco ON dados_prognostico(nivel_risco);
CREATE INDEX idx_prognostico_json_resultados ON dados_prognostico USING GIN (resultados);
CREATE INDEX idx_prognostico_json_recomendacoes ON dados_prognostico USING GIN (recomendacoes);

-- ============================================================================
-- TABELA: anexos
-- ============================================================================
CREATE TABLE IF NOT EXISTS anexos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relacionamentos (pode anexar a múltiplas entidades)
    projeto_id UUID REFERENCES projetos(id) ON DELETE CASCADE,
    tarefa_id UUID REFERENCES tarefas(id) ON DELETE CASCADE,
    diagnostico_id UUID REFERENCES dados_diagnostico(id) ON DELETE CASCADE,
    prognostico_id UUID REFERENCES dados_prognostico(id) ON DELETE CASCADE,
    
    -- Metadados do arquivo
    nome_arquivo VARCHAR(255) NOT NULL,
    tipo_arquivo VARCHAR(100), -- 'pdf', 'docx', 'xlsx', 'imagem', 'video', 'dwg'
    categoria VARCHAR(100), -- 'relatorio', 'foto', 'desenho', 'planilha', 'outros'
    tamanho_bytes BIGINT,
    
    -- Armazenamento
    storage_path VARCHAR(500), -- Caminho no MinIO/S3
    storage_bucket VARCHAR(100),
    storage_url TEXT,
    
    -- Metadados
    descricao TEXT,
    tags TEXT[],
    versao INTEGER DEFAULT 1,
    
    -- Controle de versão
    anexo_original_id UUID REFERENCES anexos(id) ON DELETE SET NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(255)
);

-- Índices para anexos
CREATE INDEX idx_anexos_projeto_id ON anexos(projeto_id);
CREATE INDEX idx_anexos_tarefa_id ON anexos(tarefa_id);
CREATE INDEX idx_anexos_tipo ON anexos(tipo_arquivo);
CREATE INDEX idx_anexos_categoria ON anexos(categoria);

-- ============================================================================
-- TABELA: auditoria (log de ações)
-- ============================================================================
CREATE TABLE IF NOT EXISTS auditoria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Contexto
    usuario_id UUID,
    usuario_nome VARCHAR(255),
    acao VARCHAR(100) NOT NULL, -- 'create', 'update', 'delete', 'status_change'
    entidade VARCHAR(100) NOT NULL, -- 'projeto', 'tarefa', 'diagnostico', etc.
    entidade_id UUID NOT NULL,
    
    -- Dados da alteração
    dados_anteriores JSONB,
    dados_novos JSONB,
    campos_alterados TEXT[],
    
    -- IP e user agent
    ip_address INET,
    user_agent TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auditoria_entidade ON auditoria(entidade, entidade_id);
CREATE INDEX idx_auditoria_usuario ON auditoria(usuario_nome);
CREATE INDEX idx_auditoria_created_at ON auditoria(created_at DESC);

-- ============================================================================
-- TABELA: sincronizacao_nocodb (controle de sync)
-- ============================================================================
CREATE TABLE IF NOT EXISTS sincronizacao_nocodb (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Configuração
    tabela_origem VARCHAR(100) NOT NULL,
    tabela_nocodb VARCHAR(100),
    projeto_nocodb_id VARCHAR(100),
    
    -- Status
    status VARCHAR(50) DEFAULT 'pendente' 
        CHECK (status IN ('pendente', 'em_andamento', 'concluido', 'erro', 'cancelado')),
    
    -- Dados
    registros_processados INTEGER DEFAULT 0,
    registros_total INTEGER DEFAULT 0,
    filtros_aplicados JSONB,
    
    -- Erros
    ultimo_erro TEXT,
    tentativas INTEGER DEFAULT 0,
    
    -- Timestamps
    iniciado_em TIMESTAMP WITH TIME ZONE,
    concluido_em TIMESTAMP WITH TIME ZONE,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FUNÇÕES E TRIGGERS
-- ============================================================================

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar triggers
CREATE TRIGGER update_empresas_updated_at BEFORE UPDATE ON empresas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projetos_updated_at BEFORE UPDATE ON projetos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tarefas_updated_at BEFORE UPDATE ON tarefas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_diagnostico_updated_at BEFORE UPDATE ON dados_diagnostico
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prognostico_updated_at BEFORE UPDATE ON dados_prognostico
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sincronizacao_updated_at BEFORE UPDATE ON sincronizacao_nocodb
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Função para atualizar contagem de anexos
CREATE OR REPLACE FUNCTION update_anexos_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Atualizar contagem na tarefa/projeto
        UPDATE tarefas 
        SET anexos_count = anexos_count + 1 
        WHERE id = NEW.tarefa_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE tarefas 
        SET anexos_count = anexos_count - 1 
        WHERE id = OLD.tarefa_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_anexos_count
AFTER INSERT OR DELETE ON anexos
FOR EACH ROW EXECUTE FUNCTION update_anexos_count();

-- Função para registrar auditoria automática
CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    usuario_nome_var VARCHAR(255) := current_user;
BEGIN
    INSERT INTO auditoria (
        usuario_nome,
        acao,
        entidade,
        entidade_id,
        dados_anteriores,
        dados_novos,
        campos_alterados
    ) VALUES (
        usuario_nome_var,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
        CASE WHEN TG_OP = 'UPDATE' THEN (
            SELECT ARRAY_AGG(key)
            FROM jsonb_each(row_to_json(NEW)::jsonb) AS new_json
            LEFT JOIN jsonb_each(row_to_json(OLD)::jsonb) AS old_json 
            ON new_json.key = old_json.key
            WHERE new_json.value IS DISTINCT FROM old_json.value
        ) ELSE NULL END
    );
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers de auditoria para tabelas principais
CREATE TRIGGER audit_empresas AFTER INSERT OR UPDATE OR DELETE ON empresas
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER audit_projetos AFTER INSERT OR UPDATE OR DELETE ON projetos
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER audit_tarefas AFTER INSERT OR UPDATE OR DELETE ON tarefas
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

-- ============================================================================
-- VIEWS PARA NOCODB E RELATÓRIOS
-- ============================================================================

-- View para dashboard de projetos
CREATE OR REPLACE VIEW vw_dashboard_projetos AS
SELECT 
    p.id,
    p.codigo_projeto,
    p.titulo,
    p.tipo_projeto,
    p.status_projeto,
    p.data_inicio,
    p.data_prevista_entrega,
    p.data_conclusao,
    
    e.razao_social,
    e.nome_fantasia,
    e.endereco_municipio || '/' || e.endereco_uf as localidade_empresa,
    
    -- Estatísticas de tarefas
    (SELECT COUNT(*) FROM tarefas t WHERE t.projeto_id = p.id) as total_tarefas,
    (SELECT COUNT(*) FROM tarefas t WHERE t.projeto_id = p.id AND t.status = 'concluida') as tarefas_concluidas,
    (SELECT COUNT(*) FROM tarefas t WHERE t.projeto_id = p.id AND t.status = 'atrasada') as tarefas_atrasadas,
    
    -- Estatísticas de anexos
    (SELECT COUNT(*) FROM anexos a WHERE a.projeto_id = p.id) as total_anexos,
    
    -- Progresso geral
    ROUND(
        COALESCE(
            (SELECT AVG(progresso) 
             FROM tarefas t 
             WHERE t.projeto_id = p.id AND t.status != 'cancelada'),
        0)
    ) as progresso_geral,
    
    p.created_at,
    p.updated_at
    
FROM projetos p
JOIN empresas e ON e.id = p.empresa_id;

-- View para workflow de tarefas
CREATE OR REPLACE VIEW vw_workflow_tarefas AS
SELECT 
    t.*,
    p.codigo_projeto,
    p.titulo as projeto_titulo,
    p.tipo_projeto,
    e.razao_social,
    
    -- Cálculos de tempo
    CASE 
        WHEN t.data_conclusao_real IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (t.data_conclusao_real - t.data_inicio_real)) / 3600
        ELSE NULL
    END as horas_executadas,
    
    -- Status avançado
    CASE 
        WHEN t.status = 'concluida' THEN 'concluida'
        WHEN t.data_conclusao_prevista < CURRENT_DATE AND t.status != 'concluida' THEN 'atrasada'
        WHEN t.progresso > 0 THEN 'em_andamento'
        ELSE 'pendente'
    END as status_detalhado,
    
    -- Dependências pendentes
    (SELECT COUNT(*) 
     FROM tarefas td 
     WHERE td.id = ANY(t.dependencias) 
     AND td.status != 'concluida') as dependencias_pendentes
    
FROM tarefas t
JOIN projetos p ON p.id = t.projeto_id
JOIN empresas e ON e.id = p.empresa_id;

-- View para exportação NocoDB
CREATE OR REPLACE VIEW vw_nocodb_projetos AS
SELECT 
    p.id as internal_id,
    p.codigo_projeto,
    p.titulo,
    p.descricao,
    p.tipo_projeto,
    p.status_projeto,
    p.data_inicio,
    p.data_prevista_entrega,
    p.data_conclusao,
    
    e.cnpj,
    e.razao_social,
    e.nome_fantasia,
    e.responsavel_tecnico as contato_empresa,
    
    p.responsavel_tecnico,
    p.coordenador_projeto,
    
    p.valor_orcado,
    p.valor_executado,
    
    -- Estatísticas
    (SELECT COUNT(*) FROM tarefas t WHERE t.projeto_id = p.id) as qtd_tarefas,
    (SELECT COUNT(*) FROM anexos a WHERE a.projeto_id = p.id) as qtd_anexos,
    
    -- Datas
    p.created_at,
    p.updated_at,
    
    -- Flags para NocoDB
    'sync' as sync_status,
    p.nocodb_record_id
    
FROM projetos p
JOIN empresas e ON e.id = p.empresa_id;

-- ============================================================================
-- FUNÇÕES DE WORKFLOW
-- ============================================================================

-- Função para atualizar status do projeto baseado nas tarefas
CREATE OR REPLACE FUNCTION atualizar_status_projeto()
RETURNS TRIGGER AS $$
DECLARE
    projeto_uuid UUID;
    total_tarefas INT;
    tarefas_concluidas INT;
    novo_status VARCHAR(50);
BEGIN
    -- Obter projeto_id da tarefa modificada
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        projeto_uuid := NEW.projeto_id;
    ELSE
        projeto_uuid := OLD.projeto_id;
    END IF;
    
    -- Contar tarefas
    SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'concluida')
    INTO total_tarefas, tarefas_concluidas
    FROM tarefas
    WHERE projeto_id = projeto_uuid AND status != 'cancelada';
    
    -- Determinar novo status
    IF total_tarefas = 0 THEN
        novo_status := 'planejamento';
    ELSIF tarefas_concluidas = total_tarefas THEN
        novo_status := 'concluido';
    ELSIF tarefas_concluidas > 0 THEN
        novo_status := 'andamento';
    ELSE
        novo_status := 'planejamento';
    END IF;
    
    -- Atualizar projeto
    UPDATE projetos 
    SET status_projeto = novo_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = projeto_uuid
    AND status_projeto != novo_status;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_status_projeto
AFTER INSERT OR UPDATE OR DELETE ON tarefas
FOR EACH ROW EXECUTE FUNCTION atualizar_status_projeto();

-- ============================================================================
-- CONFIGURAÇÕES INICIAIS
-- ============================================================================

-- Inserir tipos de projeto pré-definidos
INSERT INTO projetos (
    codigo_projeto,
    titulo,
    tipo_projeto,
    status_projeto,
    empresa_id
) VALUES 
    ('MODELO-PASSIVO', 'Modelo - Passivo Ambiental', 'passivo_ambiental', 'concluido', NULL),
    ('MODELO-PGRS', 'Modelo - PGRS', 'pgrs', 'concluido', NULL),
    ('MODELO-EMISSOES', 'Modelo - Emissões Atmosféricas', 'emissoes_atmosfericas', 'concluido', NULL),
    ('MODELO-RUIDO', 'Modelo - Laudo de Ruído', 'laudo_ruido', 'concluido', NULL)
ON CONFLICT (codigo_projeto) DO NOTHING;

-- ============================================================================
-- PERMISSÕES
-- ============================================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin;

-- Permissões específicas para NocoDB
GRANT SELECT ON ALL TABLES IN SCHEMA public TO nocodb;
GRANT INSERT, UPDATE, DELETE ON projetos, tarefas, anexos TO nocodb;
GRANT SELECT ON vw_nocodb_projetos, vw_dashboard_projetos, vw_workflow_tarefas TO nocodb;

-- ============================================================================
-- MENSAGEM FINAL
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'SCHEMA DE LAUDOS AMBIENTAIS CRIADO!';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Tabelas principais:';
    RAISE NOTICE '- empresas (cadastro básico)';
    RAISE NOTICE '- projetos (gestão de laudos)';
    RAISE NOTICE '- tarefas (workflow completo)';
    RAISE NOTICE '- dados_diagnostico (JSONB - coleta)';
    RAISE NOTICE '- dados_prognostico (JSONB - resultados)';
    RAISE NOTICE '- anexos (documentos e mídias)';
    RAISE NOTICE '- auditoria (log de ações)';
    RAISE NOTICE '- sincronizacao_nocodb (controle sync)';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Views para NocoDB:';
    RAISE NOTICE '- vw_dashboard_projetos';
    RAISE NOTICE '- vw_workflow_tarefas';
    RAISE NOTICE '- vw_nocodb_projetos';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Triggers automáticos:';
    RAISE NOTICE '- Atualização de status de projetos';
    RAISE NOTICE '- Contagem de anexos';
    RAISE NOTICE '- Auditoria completa';
    RAISE NOTICE '=========================================';
END $$;
