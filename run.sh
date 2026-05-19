#!/bin/bash

# Define a pasta do script como diretório de execução
cd "$(dirname "$0")"

echo "========================================="
echo "⚙️  Iniciando Ponte Tuya-Klipper Local"
echo "========================================="

# 1. Verifica se o ambiente virtual existe, se não, cria
if [ ! -d "venv" ]; then
    echo "📦 Ambiente virtual não encontrado. Criando venv..."
    python3 -m venv venv
fi

# 2. Ativa o ambiente virtual
echo "🔄 Ativando ambiente virtual..."
source venv/bin/activate

# 3. Instala/Atualiza as dependências de forma isolada
echo "📥 Verificando e instalando dependências..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# 4. Gerencia o arquivo .env
if [ ! -f ".env" ]; then
    echo "⚠️  Arquivo .env não configurado!"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "📝 Arquivo '.env' gerado a partir do modelo."
        echo "🛑 Edite o arquivo '.env' com suas chaves da Tuya antes de rodar novamente."
        exit 0
    else
        echo "❌ Erro catastrófico: .env.example não foi encontrado."
        exit 1
    fi
fi

# 5. Roda a aplicação Flask
echo "🚀 Servidor Flask ativo e rodando!"
echo "========================================="
python3 app.py