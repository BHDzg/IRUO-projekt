locals {
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

  prefiks = "tslab-t"

  meta = merge(var.oznake, { managed_by = "terraform" })

  # Sredisnjica (hub) = 172.16.0.0/24; spoke mreze od 172.16.20.0/24 nadalje
  hub_cidr       = cidrsubnet(var.bazni_cidr, 8, 0)
  redoslijed     = { for i, n in sort(keys(local.programeri)) : n => i }
  programer_cidr = { for n, i in local.redoslijed : n => cidrsubnet(var.bazni_cidr, 8, 20 + i) }

  slova = [for i in range(var.broj_moodle_instanci) : substr("abcdefgh", i, 1)]

  entra_domena = var.entra_domena != "" ? var.entra_domena : data.azuread_domains.tenant.domains[0].domain_name
}
