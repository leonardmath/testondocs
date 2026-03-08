# 📋 ESTRUTURA COMPLETA DO QUESTIONÁRIO DE PASSIVO AMBIENTAL

## 🎯 Visão Geral

O questionário foi expandido de **2 perguntas básicas** para um **formulário completo e detalhado** com **10 seções** baseadas na estrutura real do relatório de passivo ambiental.

**Tempo estimado:** 30-45 minutos  
**Total de campos:** ~150 campos organizados em blocos reutilizáveis

---

## 📊 Seções do Questionário

### 1️⃣ **INTRODUÇÃO**
- Explicação do processo
- Protocolo gerado automaticamente
- Tempo estimado
- Instruções de navegação

### 2️⃣ **DADOS CADASTRAIS** ✨ *Com busca automática por CNPJ*
**Arquivo:** `bloco-dados-cadastrais.yml`

Campos coletados:
- ✅ CNPJ (com busca na ReceitaWS)
- ✅ Razão Social (preenchido automaticamente)
- ✅ Nome Fantasia (preenchido automaticamente)
- ✅ Inscrição Estadual
- ✅ Inscrição Municipal

**Funcionalidade especial:** Busca automática preenchendo empresa E endereço

---

### 3️⃣ **ENDEREÇO COMPLETO** ✨ *Com busca automática por CEP*
**Arquivo:** `bloco-endereco.yml`

Campos coletados:
- ✅ CEP (com busca no ViaCEP)
- ✅ Logradouro (preenchido automaticamente)
- ✅ Número
- ✅ Complemento
- ✅ Bairro (preenchido automaticamente)
- ✅ Município (preenchido automaticamente)
- ✅ UF (lista dropdown)

**Funcionalidade especial:** Integração com API ViaCEP

---

### 4️⃣ **DADOS DE CONTATO**
**Arquivo:** `bloco-contato.yml`

Campos coletados:
- ✅ E-mail (validado)
- ✅ Telefone (formatado automaticamente)
- ✅ Celular (formatado automaticamente)
- ✅ Nome do Responsável
- ✅ Cargo/Função
- ✅ CPF do Responsável

**Validações:** Email e telefone validados automaticamente

---

### 5️⃣ **LOCALIZAÇÃO GEOGRÁFICA**
**Arquivo:** `bloco-localizacao.yml`

Campos coletados:
- ✅ Latitude (WGS84)
- ✅ Longitude (WGS84)
- ✅ Como obteve coordenadas (GPS, Maps, KMZ, Manual)
- ✅ Área do terreno (m²)
- ✅ Upload de arquivo KMZ/KML

**Funcionalidade especial:** Upload de arquivo georeferenciado

---

### 6️⃣ **HISTÓRICO DA ÁREA** 🆕
**Arquivo:** `bloco-historico.yml` (NOVO)

Campos coletados:
- ✅ Ano de início das atividades
- ✅ Atividade inicial
- ✅ Histórico de reformas e modernizações
- ✅ Substituições de tanques (datas e tipos)
- ✅ Bandeira original e atual
- ✅ Anos de mudança de bandeira
- ✅ Histórico de vazamentos/incidentes
- ✅ Autuações ambientais
- ✅ Modificações no layout físico

**Cálculo automático:** Anos de operação baseado no ano de início

---

### 7️⃣ **CARACTERIZAÇÃO DO ENTORNO** 🆕
**Arquivo:** `bloco-entorno.yml` (NOVO)

Campos coletados:

#### **Ocupação do Entorno (200m)**
- ✅ Tipo de ocupação (residencial, comercial, industrial, misto)
- ✅ Densidade de ocupação (alta, média, baixa)

#### **Edificações Sensíveis**
- ✅ Hospitais/Clínicas (quantidade)
- ✅ Escolas (quantidade)
- ✅ Creches (quantidade)
- ✅ Asilos (quantidade)
- ✅ Outras edificações (descrição)

#### **Poços Tubulares**
- ✅ Poços identificados em 500m (quantidade)
- ✅ Poços identificados em 200m (quantidade)
- ✅ Poço próprio do empreendimento
- ✅ Profundidade do poço próprio

#### **Serviços Públicos**
- ✅ Abastecimento de água (rede, poço, misto)
- ✅ Fornecimento de energia

#### **Hidrografia**
- ✅ Presença de corpos d'água
- ✅ Descrição dos corpos d'água
- ✅ Bacia hidrográfica

#### **Evolução Temporal**
- ✅ Aumento de edificações
- ✅ Período de análise

**Conformidade:** Atende IN-IAT 39/2025 e DD CETESB 038/2017

---

### 8️⃣ **CARACTERIZAÇÃO DO EMPREENDIMENTO** 🆕
**Arquivo:** `bloco-empreendimento.yml` (NOVO)

Campos coletados:

#### **Combustíveis e Operação**
- ✅ Combustíveis comercializados (múltipla escolha)
- ✅ Área total do terreno (m²)

#### **Estrutura Física**
- ✅ Cobertura da pista (sim/não, material)
- ✅ Tipo de piso (concreto usinado, simples, asfalto)
- ✅ Estado de conservação do piso

#### **Drenagem e Tratamento**
- ✅ Canaletas de drenagem (tipo: oleosas, pluviais)
- ✅ CSAO - Caixa Separadora Água/Óleo
  - Tipo (decantador, coalescente)
  - Volume (litros)
  - Frequência de limpeza

#### **Gestão de Resíduos**
- ✅ Destinação de embalagens de lubrificantes
- ✅ Destinação de óleo usado
- ✅ Destinação de resíduos contaminados

#### **Serviços Adicionais**
- ✅ Troca de óleo
- ✅ Lavador de veículos (tipo: manual, automático)
- ✅ Loja de conveniência
- ✅ Borracharia

**Conformidade:** NBR 13.786, Resolução CEMA 29/2018

---

### 9️⃣ **SISTEMA DE ARMAZENAMENTO (TANQUES)** 🆕
**Arquivo:** `bloco-tanques-detalhado.yml` (NOVO - Muito expandido!)

Campos por tanque:

#### **Identificação**
- ✅ Número/ID do tanque
- ✅ Tipo (subterrâneo parede simples/dupla, jaquetado, aéreo, ecotank)
- ✅ Tanque tripartido? (sim/não)

#### **Combustíveis** (adaptável para tripartidos)
- ✅ Combustível armazenado OU
- ✅ Compartimento 1: combustível + volume
- ✅ Compartimento 2: combustível + volume
- ✅ Compartimento 3: combustível + volume

#### **Capacidade e Construção**
- ✅ Capacidade total (m³) - calculada automaticamente para tripartidos
- ✅ Material (aço carbono, fibra, aço revestido)
- ✅ Parede dupla?
- ✅ Jaquetado?

#### **Monitoramento**
- ✅ Monitoramento intersticial?
- ✅ Tipo de monitoramento (eletrônico, manual, sensor)

#### **Instalação**
- ✅ Ano de fabricação
- ✅ Ano de instalação
- ✅ Localização (pista, externa, troca óleo)

#### **Situação**
- ✅ Situação atual (ativo, desativado, removido)
- ✅ Data de desativação

#### **Equipamentos de Proteção**
- ✅ Bocas de descarga com cruzeta (NBR 15.138)
- ✅ Câmara de contenção - Spill/Sumps (NBR 15.118)
- ✅ Sistema de respiro (suspiros)
- ✅ Válvula antitransbordamento

**Cálculos automáticos:**
- Anos de uso do tanque
- Vida útil estimada (15-20 anos conforme tipo)
- Vida útil restante
- Percentual de vida útil consumido

**Conformidade:** NBR 13.785, NBR 13.212, Resolução CEMA 29/2018, DD CETESB 125/2021/E

---

### 🔟 **BOMBAS E LINHAS DE ABASTECIMENTO** 🆕
**Arquivo:** `bloco-bombas.yml` (NOVO)

Campos coletados:

#### **Ilhas e Bombas**
- ✅ Quantidade de ilhas de abastecimento
- ✅ Quantidade de bombas
- ✅ Quantidade de bicos

#### **Tubulações**
- ✅ Material (PEAD, aço, fibra, misto)
- ✅ Enterradas?
- ✅ Profundidade média (m)
- ✅ Contenção secundária nas linhas?

#### **Sistemas de Detecção**
- ✅ Sistema de detecção de vazamento?
- ✅ Tipo de detecção (pressostático, eletrônico, visual)
- ✅ Câmaras de contenção nas abastecedoras?
- ✅ Câmaras de contenção na filtragem?

#### **Conservação e Manutenção**
- ✅ Estado de conservação das bombas
- ✅ Observações sobre vazamentos/manchas
- ✅ Frequência de manutenção
- ✅ Histórico de vazamentos anteriores

**Conformidade:** NBR 13.784, IN-IAT 39/2025

---

## 🎯 TELA FINAL - RESUMO COMPLETO

A tela final apresenta um resumo consolidado de TODOS os dados coletados:

### Seções do Resumo:
1. **Empresa** - Razão social, CNPJ, nome fantasia
2. **Localização** - Endereço completo e coordenadas
3. **Histórico** - Tempo de operação, bandeira, autuações
4. **Entorno** - Ocupação, poços, edificações sensíveis
5. **Infraestrutura** - Combustíveis, tanques, bombas, CSAO
6. **Contato** - Email, telefone, responsável

### Informações Adicionais:
- ✅ Protocolo único gerado
- ✅ Data/hora de preenchimento
- ✅ Próximos passos
- ✅ Opções: Baixar PDF, Nova avaliação, Sair

---

## 📦 Arquivos Gerados

### Blocos YAML (Reutilizáveis):
1. `bloco-dados-cadastrais.yml` - Busca CNPJ
2. `bloco-endereco.yml` - Busca CEP
3. `bloco-contato.yml` - Validação de contatos
4. `bloco-localizacao.yml` - Coordenadas e área
5. `bloco-historico.yml` - **NOVO** - Histórico completo
6. `bloco-entorno.yml` - **NOVO** - Caracterização entorno
7. `bloco-empreendimento.yml` - **NOVO** - Infraestrutura detalhada
8. `bloco-tanques-detalhado.yml` - **NOVO** - Sistema completo de tanques
9. `bloco-bombas.yml` - **NOVO** - Bombas e linhas

### Arquivo Principal:
- `passivo-ambiental-completo.yml` - Orquestra todos os blocos

### Configuração:
- `_config/listas-dados.yml` - Listas predefinidas (UFs, bandeiras, combustíveis, etc.)

---

## 🔄 Fluxo de Navegação

```
INÍCIO
  ↓
1. Introdução (explicação do processo)
  ↓
2. Busca CNPJ → Dados Cadastrais
  ↓
3. Busca CEP → Endereço Completo
  ↓
4. Dados de Contato
  ↓
5. Localização Geográfica (coordenadas, KMZ)
  ↓
6. Histórico da Área (reformas, bandeiras, incidentes)
  ↓
7. Entorno (200m/500m, poços, edificações)
  ↓
8. Empreendimento (estrutura, drenagem, resíduos)
  ↓
9. Tanques (detalhes completos por tanque)
  ↓
10. Bombas e Linhas (quantidade, estado, manutenção)
  ↓
RESUMO FINAL COMPLETO
```

---

## ✨ Funcionalidades Especiais

### 🔍 Buscas Automáticas:
1. **CNPJ** → ReceitaWS API
   - Preenche: razão social, nome fantasia, endereço completo
2. **CEP** → ViaCEP API
   - Preenche: logradouro, bairro, município, UF

### 📊 Cálculos Automáticos:
1. **Tempo de operação** (anos desde início)
2. **Vida útil dos tanques** (baseado no tipo)
3. **Vida útil restante**
4. **Percentual de uso**
5. **Capacidade total** (tanques tripartidos)
6. **Área em hectares** (conversão automática)

### ✅ Validações:
1. **CNPJ** - Algoritmo de dígitos verificadores
2. **Email** - Regex validation
3. **Telefone** - 10 ou 11 dígitos
4. **CEP** - 8 dígitos
5. **Coordenadas** - Limites WGS84

### 🎨 UX/UI:
1. **Navegação livre** via menu lateral
2. **Campos condicionais** (show if/hide)
3. **Valores padrão inteligentes**
4. **Hints e ajudas contextuais**
5. **Alertas e avisos** em pontos críticos

---

## 📈 Comparação

| Aspecto | Versão Antiga | Versão Nova |
|---------|---------------|-------------|
| **Perguntas** | 2 básicas | ~150 campos organizados |
| **Seções** | 1 | 10 seções |
| **Blocos reutilizáveis** | 0 | 9 blocos |
| **Buscas automáticas** | 0 | 2 (CNPJ + CEP) |
| **Validações** | 0 | 5 tipos |
| **Cálculos automáticos** | 0 | 6 tipos |
| **Tempo estimado** | 2 min | 30-45 min |
| **Conformidade legal** | Básica | IN-IAT 39/2025, NBRs, CEMA |

---

## 🎯 Próximos Passos Sugeridos

1. ✅ **Copiar blocos** para `/opt/stackdevops/src/docassemble/docassemble/relatorios/data/questions/_blocos/`
2. ✅ **Substituir** `passivo-ambiental.yml` pela versão completa
3. ✅ **Testar** cada seção no DocAssemble
4. ✅ **Ajustar** textos e validações conforme necessário
5. ✅ **Integrar** com API para envio dos dados
6. ✅ **Gerar PDF** do relatório final

---

## 📝 Notas Importantes

- Todos os campos são **opcionais** para permitir preenchimento gradual
- Sistema de **salvamento automático** preserva progresso
- **Menu lateral** sempre visível para navegação livre
- **Resumo final** mostra apenas campos preenchidos
- **Protocolo único** identifica cada avaliação
- **Conformidade legal** com normas ambientais brasileiras

---

**Versão:** 4.0.0  
**Data:** Dezembro 2024  
**Autor:** Sistema StackDevOps
