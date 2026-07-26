# Usporedba elemenata: OpenStack vs Azure

| Potreba | OpenStack | Azure | Napomena |
|---|---|---|---|
| Izolacija korisnika | Keystone tenant | Resource grupa + VNet + RBAC opseg | tenant je API-level granica; Azure kombinira RBAC i mrezu |
| Virtualna mreza | Neutron mreza + podmreza + usmjernik | VNet + podmreza + peering | Neutron SNAT vs platformski odlazni pristup |
| Instanca 2 vCPU/4 GB | flavor `m1.medium` | `Standard_B2s` | flavore definira operator; Azure ima fiksni katalog |
| Blok disk | Cinder volumen | Managed Disk (StandardSSD) | oba prezive VM, attach/detach |
| Balanser | Octavia (SOURCE_IP persistence) | Standard LB (`SourceIP`) ili App Gateway | vidi usporedbu ispod |
| Objektna pohrana | Swift spremnik | Blob spremnik | Swift ACL po tenantu; Blob RBAC + managed identity |
| Datotecna pohrana | Manila (NFS) | Azure Files (SMB) | Manila IP access-list; Files kljuc + service endpoint |
| IAM | Keystone racuni/skupine/role | Entra ID + RBAC custom role | Azure granularniji (pojedinacne akcije) |
| Automatizacija | provider `openstack` | provideri `azurerm` + `azuread` | isti HCL, isti CSV→JSON ulaz |
| Trosak | CAPEX + odrzavanje | OPEX ~228 USD/mj | otvoreni kod vs pay-as-you-go |

## Balanser: Azure Load Balancer vs Application Gateway

| Kriterij | Standard LB (odabrano) | Application Gateway |
|---|---|---|
| Sloj | L4 (TCP) | L7 (HTTP/HTTPS) |
| Cijena | ~18 USD/mj | ~180+ USD/mj (v2) |
| TLS terminacija, WAF, cookie affinity | ne (SourceIP affinity dostupan) | da |
| Za internu test okolinu | odlican | predimenzioniran |

Moodle bez dijeljene sesije zahtijeva session affinity: na L4 sloju to rjesava
`SourceIP` distribucija (Azure), odnosno `SOURCE_IP` persistence (Octavia).
App Gateway bi u produkciji dodao TLS offload, WAF i cookie-based affinity.

## Obrazlozenje tipa VM-a i diska

2 vCPU / 4 GB iz zadatka: `m1.medium` / `Standard_B2s` (burstable — najjeftinija
opcija tocno te velicine, idealna za povremeno opterecenje testa). Dva diska:
odvajanje OS-a od podataka (`/opt/moodle-podaci` na podatkovnom disku) omogucuje
snapshot, prosirenje i zamjenu VM-a bez gubitka podataka; Standard SSD je
kompromis cijene i performansi za test.
