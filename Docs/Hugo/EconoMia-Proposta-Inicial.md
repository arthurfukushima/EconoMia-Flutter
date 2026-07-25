# EconoMia

> _Merged into the numbered docs (01, 03, 04, 06, 07, 11) on 2026-07-23. This
> file is kept as the original proposal of record._

> **Inteligência para você economizar.**

## Visão

O EconoMia é um assistente inteligente de compras. Em vez de apenas
comparar preços, ele agrega informações de diversas fontes, normaliza
produtos usando IA e ajuda o usuário a encontrar a melhor estratégia de
compra.

A personagem **Mia** é a voz do aplicativo.

Exemplos:

-   🐱 "Encontrei uma economia de R\$ 48 hoje."
-   🐱 "Achei uma marca equivalente 18% mais barata."
-   🐱 "Hoje vale mais a pena comprar no Muffato."

------------------------------------------------------------------------

# Problema

Consumidores:

-   Não sabem qual mercado está realmente mais barato.
-   Precisam abrir vários aplicativos.
-   Não conseguem comparar uma compra inteira.
-   Não sabem quanto economizaram.
-   Não possuem histórico de preços.

Mercados:

-   Possuem pouca inteligência para divulgar promoções.
-   Dependem de panfletos e campanhas limitadas.

------------------------------------------------------------------------

# Proposta de Valor

Transformar milhares de preços desorganizados em informação útil.

Não somos um comparador de preços.

Somos uma plataforma de inteligência de compras.

------------------------------------------------------------------------

# Arquitetura

## 1. Camada de Origem

Fontes:

-   QR Code / NFC-e
-   Comunidade
-   Panfletos (OCR + IA)
-   Planilhas dos mercados
-   APIs parceiras
-   Crawlers
-   Equipe própria

Todas geram um registro RawPrice contendo:

-   source
-   market
-   description
-   price
-   quantity
-   unit
-   date
-   confidence
-   location

------------------------------------------------------------------------

## 2. Camada de Normalização

Responsável por:

-   Agrupar produtos equivalentes
-   Corrigir descrições
-   Padronizar unidades
-   Identificar marcas
-   Criar Produtos Canônicos

Exemplo:

ARROZ NIKOH 5KG

↓

Produto Canônico

Categoria: Arroz Japonês

Marca: Nikkoh

Peso: 5kg

------------------------------------------------------------------------

## 3. Camada de Inteligência

Funcionalidades:

-   Melhor mercado
-   Melhor combinação entre mercados
-   Produtos equivalentes
-   Histórico de preços
-   Alertas
-   Sugestões da Mia
-   Economia estimada

------------------------------------------------------------------------

## 4. Cliente

Flutter

-   Android
-   iOS
-   Web
-   Desktop (futuro)

------------------------------------------------------------------------

# Stack Técnica

Frontend

-   Flutter
-   Riverpod
-   GoRouter

Backend

-   PostgreSQL
-   Redis
-   Firebase Auth
-   Cloud Storage
-   Workers para OCR e IA

IA

-   OCR
-   LLM para normalização
-   Embeddings para similaridade

------------------------------------------------------------------------

# Banco

Tabelas principais

-   Products
-   CanonicalProducts
-   Aliases
-   Brands
-   Categories
-   Markets
-   Prices
-   PriceHistory
-   ShoppingLists
-   ShoppingListItems
-   Sources
-   Users

------------------------------------------------------------------------

# Fluxos

## Lista Inteligente

Usuário cria lista

↓

Mia encontra:

-   Melhor mercado
-   Melhor combinação
-   Economia prevista

------------------------------------------------------------------------

## Comparação

Produto

↓

Mercados

↓

Histórico

↓

Equivalentes

------------------------------------------------------------------------

## Compra

Usuário marca itens comprados

↓

Mia calcula

-   Economia
-   Histórico
-   Estatísticas

------------------------------------------------------------------------

# Sistema de Confiança

Cada preço recebe um score.

Influenciado por:

-   Fonte
-   Idade
-   Confirmações
-   Divergência
-   Reputação

Exemplo

R\$ 18,90

Confiança 98%

Confirmado hoje por 7 usuários.

------------------------------------------------------------------------

# Monetização

B2C

-   Premium
-   Alertas
-   Histórico
-   IA
-   Cashback
-   Afiliados

B2B

-   Produtos patrocinados
-   Mercados patrocinados
-   Dashboard de inteligência
-   API de preços

------------------------------------------------------------------------

# Branding

## Nome

**EconoMia**

A marca principal.

## Personagem

**Mia**

Uma gata curiosa e inteligente.

Personalidade:

-   objetiva
-   simpática
-   prestativa
-   observadora
-   caçadora de boas ofertas

Nunca infantil.

Sempre útil.

Exemplos:

> "Encontrei uma economia para você."

> "Vale esperar até sexta."

> "Achei uma opção melhor."

------------------------------------------------------------------------

# Identidade Visual

Paleta

-   Verde → confiança e economia
-   Creme → acolhimento
-   Laranja → oportunidade

Estilo

-   Minimalista
-   Cantos arredondados
-   Poucas cores
-   Microanimações

A Mia deve aparecer em:

-   onboarding
-   loading
-   notificações
-   dicas
-   tela inicial

------------------------------------------------------------------------

# Roadmap MVP

## Fase 1

-   Scanner QR Code
-   Busca de produtos
-   Comparação de preços
-   Histórico simples

## Fase 2

-   Lista inteligente
-   Melhor combinação
-   Economia estimada

## Fase 3

-   OCR de panfletos
-   Comunidade
-   Confirmação de preços

## Fase 4

-   IA completa
-   Construção
-   Farmácia
-   Compra online

------------------------------------------------------------------------

# Visão

"O EconoMia é a plataforma que transforma preços espalhados pela
internet em inteligência para ajudar pessoas a comprar melhor."

O usuário não abre apenas um comparador de preços.

Ele abre a Mia.
