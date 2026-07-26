#!/usr/bin/env bash
# =============================================================================
#  TechSprint / ts-moodle-lab — jedina ulazna skripta projekta (pokrece se JEDNOM)
#
#  Skripta prima putanju do CSV datoteke (ime;prezime;rola), pretvara je u
#  korisnici.auto.tfvars.json te Terraformom podize kompletnu infrastrukturu
#  za varijabilan broj korisnika u OpenStack i/ili Azure oblaku.
#
#  Koristenje:
#    ./pokreni.sh [-c openstack|azure|oba] [-a provjera|plan|primjena|rusenje] <putanja/do.csv>
#
#  Primjeri:
#    ./pokreni.sh podaci/tim.csv                       # provjera (validate) za oba oblaka
#    ./pokreni.sh -c openstack -a primjena podaci/tim.csv
#    ./pokreni.sh -c azure -a plan podaci/tim.csv
#    ./pokreni.sh -c oba -a rusenje podaci/tim.csv
# =============================================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

OBLAK="oba"
AKCIJA="provjera"

ispis()  { printf '\033[1;36m>>>\033[0m %s\n' "$*"; }
greska() { printf '\033[1;31mGRESKA:\033[0m %s\n' "$*" >&2; exit 1; }

while getopts ":c:a:h" opt; do
  case "$opt" in
    c) OBLAK="$OPTARG" ;;
    a) AKCIJA="$OPTARG" ;;
    h) sed -n '2,17p' "$0"; exit 0 ;;
    \?) greska "Nepoznata opcija: -$OPTARG (pomoc: ./pokreni.sh -h)" ;;
    :)  greska "Opcija -$OPTARG zahtijeva vrijednost" ;;
  esac
done
shift $((OPTIND - 1))

CSV="${1:-}"
[ -n "$CSV" ] || greska "Nedostaje putanja do CSV-a. Primjer: ./pokreni.sh podaci/tim.csv"
[ -f "$CSV" ] || greska "CSV ne postoji: $CSV"

# -----------------------------------------------------------------------------
# 1) CSV -> JSON (korisnici.auto.tfvars.json) uz validaciju sadrzaja
#    - zaglavlje mora biti: ime;prezime;rola
#    - role: developer | devops_lead
#    - tocno jedan devops_lead, barem jedan developer
# -----------------------------------------------------------------------------
JSON="$(awk -F';' '
  NR==1 {
    gsub(/\r/,"")
    if ($0 != "ime;prezime;rola") { printf "HDR:%s", $0 > "/dev/stderr"; kod=2; exit 2 }
    next
  }
  {
    gsub(/\r/,""); gsub(/^[ \t]+|[ \t]+$/,"",$1); gsub(/^[ \t]+|[ \t]+$/,"",$2); gsub(/^[ \t]+|[ \t]+$/,"",$3)
    if ($1=="" && $2=="" && $3=="") next
    if ($1=="" || $2=="" || $3=="") { printf "ROW:%d", NR > "/dev/stderr"; kod=3; exit 3 }
    if ($3!="developer" && $3!="devops_lead") { printf "ROLA:%s", $3 > "/dev/stderr"; kod=4; exit 4 }
    if ($3=="devops_lead") lead++
    if ($3=="developer")   dev++
    zapis = sprintf("{\"ime\":\"%s\",\"prezime\":\"%s\",\"rola\":\"%s\"}", tolower($1), tolower($2), $3)
    lista = (lista=="" ? zapis : lista "," zapis)
  }
  END {
    if (kod) exit kod
    if (lead != 1) { printf "LEAD:%d", lead > "/dev/stderr"; exit 5 }
    if (dev  < 1)  { printf "DEV:%d",  dev  > "/dev/stderr"; exit 6 }
    printf "{\"korisnici\":[%s]}", lista
  }' "$CSV" 2>/tmp/pokreni-csv-err)" || {
    kod=$?
    razlog="$(cat /tmp/pokreni-csv-err 2>/dev/null || true)"
    case "$kod" in
      2) greska "Neispravno CSV zaglavlje (${razlog#HDR:}) — ocekivano: ime;prezime;rola" ;;
      3) greska "Nepotpun redak br. ${razlog#ROW:} u CSV-u" ;;
      4) greska "Nepoznata rola '${razlog#ROLA:}' — dozvoljeno: developer, devops_lead" ;;
      5) greska "CSV mora imati tocno jednog devops_lead (nadjeno: ${razlog#LEAD:})" ;;
      6) greska "CSV mora imati barem jednog developera" ;;
      *) greska "Neuspjelo citanje CSV-a" ;;
    esac
  }

ispis "CSV je ispravan: $CSV"

# -----------------------------------------------------------------------------
# 2) Odabir okolina i predaja korisnika Terraformu (JSON tfvars)
# -----------------------------------------------------------------------------
case "$OBLAK" in
  openstack) OKOLINE=(openstack) ;;
  azure)     OKOLINE=(azure) ;;
  oba)       OKOLINE=(openstack azure) ;;
  *)         greska "Nepoznat oblak: $OBLAK (openstack|azure|oba)" ;;
esac

command -v terraform >/dev/null || greska "Terraform nije instaliran"

for dir in "${OKOLINE[@]}"; do
  printf '%s\n' "$JSON" > "$dir/korisnici.auto.tfvars.json"
  ispis "[$dir] zapisan korisnici.auto.tfvars.json"

  ispis "[$dir] terraform init"
  terraform -chdir="$dir" init -input=false >/dev/null

  case "$AKCIJA" in
    provjera) ispis "[$dir] terraform validate"
              terraform -chdir="$dir" validate ;;
    plan)     ispis "[$dir] terraform plan"
              terraform -chdir="$dir" plan -input=false ;;
    primjena) ispis "[$dir] terraform apply"
              terraform -chdir="$dir" apply -input=false -auto-approve ;;
    rusenje)  ispis "[$dir] terraform destroy"
              terraform -chdir="$dir" destroy -input=false -auto-approve ;;
    *)        greska "Nepoznata akcija: $AKCIJA (provjera|plan|primjena|rusenje)" ;;
  esac
done

ispis "Zavrseno: oblak=$OBLAK, akcija=$AKCIJA, korisnici iz: $CSV"
