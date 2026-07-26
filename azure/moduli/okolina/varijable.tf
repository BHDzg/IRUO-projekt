variable "vlasnik" {
  description = "Korisnicko ime programera (npr. fnovak)"
  type        = string
}

variable "osoba" {
  type = object({
    ime      = string
    prezime  = string
    nadimak  = string
    rola     = string
    voditelj = bool
  })
}

variable "prefiks" {
  type = string
}
variable "regija" {
  type = string
}
variable "oznake" {
  type = map(string)
}

variable "vnet_cidr" {
  type = string
}
variable "hub_cidr" {
  type = string
}
variable "hub_vnet_id" {
  type = string
}

variable "velicina" {
  type = string
}
variable "admin_racun" {
  type = string
}
variable "javni_ssh_kljuc" {
  type = string
}
variable "slika" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}
variable "slika_ima_plan" {
  type = bool
}

variable "velicina_podatkovnog" {
  type = number
}
variable "kvota_share" {
  type = number
}
variable "slova_instanci" {
  type = list(string)
}
