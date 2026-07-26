# =============================================================================
# Ulazne varijable — OpenStack okolina
# =============================================================================

# Korisnici stizu iz korisnici.auto.tfvars.json kojeg generira pokreni.sh
# iz CSV datoteke (ime;prezime;rola).
variable "korisnici" {
  description = "Popis korisnika iz CSV-a (generira pokreni.sh)"
  type = list(object({
    ime     = string
    prezime = string
    rola    = string
  }))
  default = []

  validation {
    condition     = length([for k in var.korisnici : k if k.rola == "devops_lead"]) <= 1
    error_message = "Dozvoljen je najvise jedan devops_lead."
  }
}

# --- Obavezni tagovi projekta ---
variable "oznake" {
  description = "Obavezne oznake (tagovi) svih resursa"
  type        = map(string)
  default = {
    project     = "techsprint"
    environment = "testing"
  }
}

# --- OpenStack prijava (moze i preko OS_* varijabli okoline) ---
variable "os_auth_url" {
  type    = string
  default = ""
}
variable "os_korisnik" {
  type    = string
  default = ""
}
variable "os_lozinka" {
  type      = string
  default   = ""
  sensitive = true
}
variable "os_projekt" {
  type    = string
  default = ""
}
variable "os_domena" {
  type    = string
  default = "Default"
}
variable "os_regija" {
  type    = string
  default = ""
}

# --- Slika i velicine ---
variable "slika" {
  description = "Cloud slika OS-a (Rocky Linux 9 ili CentOS Stream 9)"
  type        = string
  default     = "rocky-9-cloud"
}

variable "velicina_moodle" {
  description = "Flavor Moodle instanci — mora imati 2 vCPU / 4 GB RAM"
  type        = string
  default     = "m1.medium"
}

variable "velicina_pristupnik" {
  description = "Flavor pristupnika (jump host) i lead racunala"
  type        = string
  default     = "m1.small"
}

# --- Mreza ---
variable "vanjska_mreza" {
  description = "Naziv vanjske (provider) mreze"
  type        = string
  default     = "public"
}

variable "bazni_cidr" {
  description = "Bazni adresni prostor; svaki programer dobiva /24 iz njega"
  type        = string
  default     = "10.77.0.0/16"
}

variable "dns_posluzitelji" {
  type    = list(string)
  default = ["1.1.1.1", "9.9.9.9"]
}

variable "javni_ssh_kljuc" {
  description = "Javni SSH kljuc koji se postavlja na sve instance"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMYEMqWNuq0t+7+me0brNHaTF3fFa6Ckc5d6CZtWSAy tslab-kljuc"
}

# --- Diskovi i pohrana ---
variable "velicina_podatkovnog_gb" {
  description = "Velicina drugog (podatkovnog) diska po instanci, GB"
  type        = number
  default     = 24
}

variable "velicina_nfs_gb" {
  description = "Velicina NFS (Manila) share-a za sigurnosne kopije, GB"
  type        = number
  default     = 24
}

variable "broj_moodle_instanci" {
  description = "Broj Moodle instanci po programeru (2 = visoka dostupnost)"
  type        = number
  default     = 2

  validation {
    condition     = var.broj_moodle_instanci >= 2 && var.broj_moodle_instanci <= 8
    error_message = "Dozvoljeno je 2 do 8 instanci."
  }
}
