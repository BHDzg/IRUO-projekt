# ts-moodle-lab — TechSprint izolirane testne okoline za Moodle

Automatizirano kreiranje sigurnih, medjusobno izoliranih testnih okolina za
programere agencije TechSprint, realizirano **Terraformom** na **dva oblaka**:
OpenStack i Microsoft Azure. Izvor istine je CSV datoteka s korisnicima —
skripta `run.sh` pretvara je u JSON i predaje Terraformu, pa broj okolina
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
├── run.sh                  # JEDINA ulazna skripta (CSV → JSON → Terraform)
├── data/team.csv              # ulaz: ime;prezime;rola
├── openstack/                  # Terraform za OpenStack
│   ├── iam.tf                  #   Keystone tenanti/racuni/skupine/role
│   ├── access.tf              #   pristupnik + racunalo voditelja
│   ├── environments.tf              #   for_each ⇒ modules/environment po programeru
│   └── modules/environment/         #   mreza, sigurnost, pohrana, racunala, balanser
├── azure/                      # Terraform za Azure (hub-and-spoke)
│   ├── iam.tf                  #   Entra ID + custom RBAC rola
│   ├── hub.tf          #   hub VNet, pristupnik, voditelj, peering
│   ├── environments.tf              #   for_each ⇒ modules/environment po programeru
│   └── modules/environment/         #   spoke VNet, NSG/ASG, pohrana, VM-ovi, balanser
└── docs/              # dijagrami, troskovi, usporedbe, konvencije
```

## Pokretanje

Preduvjeti: Terraform ≥ 1.5. OpenStack: `source openrc` (ili `os-lab.tfvars`).
Azure: `az login` i jednokratno:

```bash
az vm image terms accept --publisher resf --offer rockylinux-x86_64 --plan 9-base
```

Skripta se pokrece **jednom**, s putanjom do CSV-a:

```bash
./run.sh data/team.csv                          # provjera (validate), oba oblaka
./run.sh -c openstack -a primjena data/team.csv # deploy OpenStack
./run.sh -c azure     -a primjena data/team.csv # deploy Azure
./run.sh -c oba       -a plan     data/team.csv # plan za oba
./run.sh -c oba       -a rusenje  data/team.csv # rusenje svega
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
| [docs/naming-and-tags.md](docs/naming-and-tags.md) | konvencija imenovanja + tagovi |
| [docs/openstack-architecture.md](docs/openstack-architecture.md) | OpenStack dijagram i odluke |
| [docs/azure-architecture.md](docs/azure-architecture.md) | Azure dijagram i odluke |
| [docs/iam-models.md](docs/iam-models.md) | Keystone IAM + Azure RBAC dijagrami |
| [docs/azure-costs.md](docs/azure-costs.md) | mjesecna procjena troskova |
| [docs/services-comparison.md](docs/services-comparison.md) | usporedba Azure/OpenStack + LB usporedba |
| [docs/network-design.md](docs/network-design.md) | objasnjenje mreznih postavki |
