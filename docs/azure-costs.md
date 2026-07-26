# Procjena mjesecnih troskova — Azure

Pretpostavke: regija **West Europe**, pay-as-you-go, 730 h/mj (24/7),
2 programera + 1 voditelj. Okvirne cijene (USD, bez PDV-a); za predaju
provjeriti u Azure Pricing Calculatoru.

| Stavka | Kol. | Jed./mj | Ukupno/mj |
|---|---:|---:|---:|
| VM Standard_B2s (Moodle, 2 vCPU/4 GB) | 4 | ~33 USD | ~132 USD |
| VM Standard_B1s (pristupnik + voditelj) | 2 | ~10 USD | ~20 USD |
| OS disk Standard SSD (E4) | 6 | ~3 USD | ~18 USD |
| Podatkovni disk Standard SSD (E4, 24→32 GB tier) | 4 | ~3 USD | ~12 USD |
| Interni Standard balanser | 2 | ~18 USD | ~36 USD |
| Public IP (Standard) | 1 | ~4 USD | ~4 USD |
| Blob LRS (~20 GB + transakcije) | 2 | ~1 USD | ~2 USD |
| Azure Files LRS (24 GB) | 2 | ~2 USD | ~4 USD |
| VNet peering (~10 GB) | — | ~0,2 USD | ~0,4 USD |
| **UKUPNO** | | | **~228 USD/mj** |

Smanjenje troska: B-serija se naplacuje samo dok VM radi — `deallocate` nocu i
vikendom (12/5) rusi trosak VM-ova za ~65 %. Upravo zato programeri kroz custom
RBAC rolu imaju pravo start/deallocate nad svojim VM-ovima.
