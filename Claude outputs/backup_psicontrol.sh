#!/bin/sh
# ============================================================
#  Backup do PsiControl
#  Baixa TUDO que está no Supabase e salva em arquivos JSON
#  numa pasta com a data de hoje, aqui do lado deste script.
#
#  Como usar:
#    1. Salve este arquivo na Área de Trabalho (NÃO dentro da
#       pasta PsiControl, para não ir parar no site).
#    2. Clique com o botão direito na Área de Trabalho e escolha
#       "Open Git Bash here".
#    3. Digite:  sh backup_psicontrol.sh
# ============================================================

URL="https://nntvdmunpudovuiwrccz.supabase.co/rest/v1"
KEY="sb_publishable_Z5XoCu4LUyMZjnMPCUZ1wg_IgphMzcf"

QUANDO=$(date +%Y-%m-%d_%Hh%M)
DEST="PsiControl-backup_$QUANDO"
mkdir -p "$DEST"

echo ""
echo "Salvando em: $DEST"
echo "------------------------------------------------------------"

TUDO_OK=1

for TABELA in usuarios dados_usuario prontuarios documentos_gerados diario_avaliacao
do
  ARQ="$DEST/$TABELA.json"

  curl -s \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" \
    "$URL/$TABELA?select=*" \
    -o "$ARQ"

  TAM=$(wc -c < "$ARQ" | tr -d ' ')

  # Um retorno vazio "[]" tem 2 bytes. Menos que isso, ou uma
  # resposta com "message", quer dizer que algo deu errado.
  if grep -q '"message"' "$ARQ" 2>/dev/null; then
    echo "  [FALHOU]  $TABELA  — o servidor recusou"
    TUDO_OK=0
  elif [ "$TAM" -le 2 ]; then
    echo "  [VAZIO]   $TABELA  — nenhum registro veio"
    TUDO_OK=0
  else
    echo "  [ok]      $TABELA  — $TAM bytes"
  fi
done

echo "------------------------------------------------------------"

if [ "$TUDO_OK" -eq 1 ]; then
  echo "Backup concluido. Guarde a pasta $DEST em outro lugar tambem"
  echo "(pen drive, Google Drive), fora deste computador."
else
  echo "ATENCAO: alguma tabela nao veio completa. Nao apague nada e"
  echo "avise antes de seguir com as mudancas."
fi

echo ""
