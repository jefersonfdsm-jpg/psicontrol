#!/bin/sh
# ============================================================
#  Conferência do backup do PsiControl
#
#  Pergunta ao servidor quantos registros existem de verdade em
#  cada tabela, para garantir que o backup não veio cortado.
#  O Supabase entrega no máximo 1000 registros por vez, então
#  qualquer tabela com 1000 ou mais precisa de tratamento
#  especial.
#
#  Rode do mesmo jeito que o outro, na Área de Trabalho:
#      sh conferir_backup.sh
# ============================================================

URL="https://nntvdmunpudovuiwrccz.supabase.co/rest/v1"
KEY="sb_publishable_Z5XoCu4LUyMZjnMPCUZ1wg_IgphMzcf"

echo ""
echo "Registros que existem no servidor:"
echo "------------------------------------------------------------"

ALERTA=0

for TABELA in usuarios dados_usuario prontuarios documentos_gerados diario_avaliacao
do
  TOTAL=$(curl -s -D - -o /dev/null \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" \
    -H "Range: 0-0" \
    -H "Prefer: count=exact" \
    "$URL/$TABELA?select=id" \
    | tr -d '\r' \
    | grep -i '^content-range:' \
    | sed 's#.*/##')

  case "$TOTAL" in
    ''|*[!0-9]*)
      echo "  $TABELA: nao consegui contar"
      ALERTA=1
      ;;
    *)
      if [ "$TOTAL" -ge 1000 ]; then
        echo "  $TABELA: $TOTAL registros   <-- PASSOU DE 1000, o backup veio cortado"
        ALERTA=1
      else
        echo "  $TABELA: $TOTAL registros"
      fi
      ;;
  esac
done

echo "------------------------------------------------------------"

if [ "$ALERTA" -eq 0 ]; then
  echo "Tudo abaixo de 1000. O backup que voce ja fez esta completo."
else
  echo "Tem tabela acima de 1000 (ou que nao deu para contar)."
  echo "Me avise antes de seguir, que eu ajusto o script."
fi

echo ""
