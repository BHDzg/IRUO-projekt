# ts-moodle-lab — TechSprint izolirane testne okoline za Moodle

Automatizirano kreiranje sigurnih, medjusobno izoliranih testnih okolina za
programere agencije TechSprint, realizirano **Terraformom** na **dva oblaka**:
OpenStack i Microsoft Azure. Izvor istine je CSV datoteka s korisnicima —
skripta `pokreni.sh` pretvara je u JSON i predaje Terraformu, pa broj okolina
ovisi iskljucivo o broju redaka u CSV-u.

## Sto dobiva svaki programer

* vlastitu **izoliranu mrezu** (OpenStack tenant / Azure RG + VNet)
* **dvije Moodle instance** `moodle-a` i `moodle-b` (2 vCPU / 4 GB —
  `m1.medium` / `Standard_B2s`) — simulacija visoke dostupnosti
* **dva diska po instanci**: OS + podatkovni (automatski formatiran i montiran)
* **interni balanser** sa session persistencijom (Octavia SOURCE_IP /
  Azure LB SourceIP) i health nadzorom na `/status.html`
* **objektnu pohranu** (Swift / Blob) i **datotecnu pohranu** za sigurnosne
  kopije (Manila NFS / Azure Files) — obje automatski montirane, least-privilege
* racun s pravom **start/stop iskljucivo vlastitih** instanci

Zajednicki dio: **pristupnik** (jump host — jedina javna IP adresa) i
**racunalo voditelja** koje se SSH-om spaja na sve instance i ima power
kontrolu nad svima.

## Struktura

```
.
├── pokreni.sh                  # JEDINA ulazna skripta (CSV → JSON → Terraform)
├── podaci/tim.csv              # ulaz: ime;prezime;rola
├── openstack/                  # Terraform za OpenStack
│   ├── iam.tf                  #   Keystone tenanti/racuni/skupine/role
│   ├── pristup.tf              #   pristupnik + racunalo voditelja
│   ├── okoline.tf              #   for_each ⇒ moduli/okolina po programeru
│   └── moduli/okolina/         #   mreza, sigurnost, pohrana, racunala, balanser
├── azure/                      # Terraform za Azure (hub-and-spoke)
│   ├── iam.tf                  #   Entra ID + custom RBAC rola
│   ├── sredisnjica.tf          #   hub VNet, pristupnik, voditelj, peering
│   ├── okoline.tf              #   for_each ⇒ moduli/okolina po programeru
│   └── moduli/okolina/         #   spoke VNet, NSG/ASG, pohrana, VM-ovi, balanser
└── dokumentacija/              # dijagrami, troskovi, usporedbe, konvencije
```

## Pokretanje

Preduvjeti: Terraform ≥ 1.5. OpenStack: `source openrc` (ili `os-lab.tfvars`).
Azure: `az login` i jednokratno:

```bash
az vm image terms accept --publisher resf --offer rockylinux-x86_64 --plan 9-base
```

Skripta se pokrece **jednom**, s putanjom do CSV-a:

```bash
./pokreni.sh podaci/tim.csv                          # provjera (validate), oba oblaka
./pokreni.sh -c openstack -a primjena podaci/tim.csv # deploy OpenStack
./pokreni.sh -c azure     -a primjena podaci/tim.csv # deploy Azure
./pokreni.sh -c oba       -a plan     podaci/tim.csv # plan za oba
./pokreni.sh -c oba       -a rusenje  podaci/tim.csv # rusenje svega
```

CSV format (tocno jedan `devops_lead`, proizvoljno developera):

```csv
ime;prezime;rola
karla;kovac;devops_lead
filip;novak;developer
lucija;babic;developer
```

## SSH pristup (samo kroz pristupnik)

```bash
ssh -J rocky@<JAVNA_IP_PRISTUPNIKA> rocky@<IP_VODITELJA>       # OpenStack
ssh -J labadmin@<JAVNA_IP_PRISTUPNIKA> labadmin@<PRIVATNA_IP>  # Azure
```

Adrese i sazetak okolina: `terraform output`; pocetne lozinke racuna:
`terraform output -json pocetne_lozinke`.

## Dokumentacija

| Datoteka | Sadrzaj |
|---|---|
| [dokumentacija/imenovanje-i-oznake.md](dokumentacija/imenovanje-i-oznake.md) | konvencija imenovanja + tagovi |
| [dokumentacija/arhitektura-openstack.md](dokumentacija/arhitektura-openstack.md) | OpenStack dijagram i odluke |
| [dokumentacija/arhitektura-azure.md](dokumentacija/arhitektura-azure.md) | Azure dijagram i odluke |
| [dokumentacija/iam-modeli.md](dokumentacija/iam-modeli.md) | Keystone IAM + Azure RBAC dijagrami |
| [dokumentacija/troskovi-azure.md](dokumentacija/troskovi-azure.md) | mjesecna procjena troskova |
| [dokumentacija/usporedba-elemenata.md](dokumentacija/usporedba-elemenata.md) | usporedba Azure/OpenStack + LB usporedba |
| [dokumentacija/mrezne-postavke.md](dokumentacija/mrezne-postavke.md) | objasnjenje mreznih postavki |
| [dokumentacija/video-scenarij.md](dokumentacija/video-scenarij.md) | scenarij za YouTube snimku |
