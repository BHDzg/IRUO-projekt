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
variable "oznake" {
  type = map(string)
}
variable "tenant_id" {
  description = "ID Keystone tenanta programera (Swift ACL, least-privilege)"
  type        = string
}

variable "slika" {
  type = string
}
variable "velicina" {
  type = string
}
variable "kljuc" {
  type = string
}
variable "vanjska_mreza_id" {
  type = string
}
variable "podmreza_cidr" {
  type = string
}
variable "dns_posluzitelji" {
  type = list(string)
}
variable "velicina_podatkovnog" {
  type = number
}
variable "velicina_nfs" {
  type = number
}
variable "slova_instanci" {
  type = list(string)
}
