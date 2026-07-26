# Konvencija imenovanja i oznake (tagovi)

## Obrazac imenovanja

```
tslab-t-<vlasnik>-<resurs>[-<slovo>]
```

| Dio | Znacenje | Primjeri |
|---|---|---|
| `tslab` | TechSprint laboratorij | fiksno |
| `t` | okolina: t = testing (p = production) | `t` |
| `<vlasnik>` | `mgmt` za zajednicke resurse ili korisnicko ime programera | `mgmt`, `fnovak`, `lbabic` |
| `<resurs>` | naziv vrste resursa (hrvatski) | `mreza`, `podmreza`, `usmjernik`, `sg`/`nsg`, `asg`, `rg`, `vnet`, `balanser`, `moodle`, `podatkovni`, `objekti`, `sigkopije`, `pristupnik`, `voditelj` |
| `<slovo>` | oznaka instance kad ih je vise | `a`, `b` |

Korisnicko ime izvodi se iz CSV-a kao **prvo slovo imena + prezime** (filip novak → `fnovak`).

Primjeri: `tslab-t-fnovak-moodle-a` (instanca), `tslab-t-fnovak-balanser` (LB),
`tslab-t-mgmt-pristupnik` (jump host), `tslab-t-lbabic-podatkovni-b` (disk).

Iznimka: Azure storage account dopusta samo mala slova i brojke uz globalno
jedinstveno ime, pa se koristi `tslab<vlasnik><sufiks>` (npr. `tslabfnovakx7k2q1`).

## Oznake (tagovi)

| Oznaka | Vrijednost | Napomena |
|---|---|---|
| `project` | `techsprint` | obavezno po projektnom zadatku |
| `environment` | `testing` | obavezno po projektnom zadatku |
| `managed_by` | `terraform` | operativna oznaka |
| `owner` | `mgmt` / korisnicko ime | vlasnistvo resursa |
| `role` | `bastion` / `devops_lead` / `developer` | uloga resursa |

Azure: standardni resource tagovi. OpenStack: Neutron tagovi `kljuc:vrijednost`
te metadata na instancama, diskovima i pohrani.
