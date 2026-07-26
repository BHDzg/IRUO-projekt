# =============================================================================
# Izvedene vrijednosti: korisnici, imenovanje, adresni plan
# =============================================================================
locals {
  # Korisnicko ime: prvo slovo imena + prezime  (filip novak -> fnovak)
  svi = { for k in var.korisnici :
    "${substr(k.ime, 0, 1)}${k.prezime}" => {
      ime      = k.ime
      prezime  = k.prezime
      nadimak  = "${substr(k.ime, 0, 1)}${k.prezime}"
      rola     = k.rola
      voditelj = k.rola == "devops_lead"
    }
  }

  programeri = { for n, k in local.svi : n => k if k.rola == "developer" }
  voditelji  = { for n, k in local.svi : n => k if k.rola == "devops_lead" }

  # Konvencija imenovanja: tslab-t-<vlasnik>-<resurs>[-<slovo>]
  prefiks = "tslab-t"

  oznake_lista = [for kljuc, vr in var.oznake : "${kljuc}:${vr}"]
  meta_zajednicko = merge(var.oznake, { managed_by = "terraform" })

  # Deterministicki adresni plan: mgmt mreza je 10.77.0.0/24, a programeri
  # dobivaju /24 podmreze od 10.77.100.0/24 nadalje (abecedni redoslijed).
  mgmt_cidr      = cidrsubnet(var.bazni_cidr, 8, 0)
  redoslijed     = { for i, n in sort(keys(local.programeri)) : n => i }
  programer_cidr = { for n, i in local.redoslijed : n => cidrsubnet(var.bazni_cidr, 8, 100 + i) }

  # Instance se oznacavaju slovima: moodle-a, moodle-b, ...
  slova = [for i in range(var.broj_moodle_instanci) : substr("abcdefgh", i, 1)]
}
