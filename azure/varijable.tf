# =============================================================================
# Ulazne varijable — Azure okolina
# =============================================================================

# Korisnici stizu iz korisnici.auto.tfvars.json kojeg generira pokreni.sh
variable "korisnici" {
  description = "Popis korisnika iz CSV-a (generira pokreni.sh)"
  type = list(object({
    ime     = string
    prezime = string
    rola    = string
  }))
  default = []
}

variable "pretplata_id" {
  description = "Azure subscription ID (ili ARM_SUBSCRIPTION_ID)"
  type        = string
  default     = ""
}

variable "regija" {
  description = "Azure regija"
  type        = string
  default     = "westeurope"
}

variable "oznake" {
  description = "Obavezne oznake (tagovi) svih resursa"
  type        = map(string)
  default = {
    project     = "techsprint"
    environment = "testing"
  }
}

# --- Mreza ---
variable "bazni_cidr" {
  description = "Bazni adresni prostor; sredisnjica i svaki spoke dobivaju /24"
  type        = string
  default     = "172.16.0.0/16"
}

# --- Racunala ---
variable "velicina_moodle" {
  description = "Velicina Moodle VM-ova — B2s ima tocno 2 vCPU / 4 GB RAM"
  type        = string
  default     = "Standard_B2s"
}

variable "velicina_mgmt" {
  description = "Velicina pristupnika i voditeljevog racunala"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_racun" {
  description = "Administratorski korisnik na svim VM-ovima"
  type        = string
  default     = "labadmin"
}

variable "javni_ssh_kljuc" {
  description = "Javni SSH kljuc za sve VM-ove"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMYEMqWNuq0t+7+me0brNHaTF3fFa6Ckc5d6CZtWSAy tslab-kljuc"
}

# --- Slika OS-a: Rocky Linux 9 ---
# Jednokratno prihvatiti uvjete marketplace slike:
#   az vm image terms accept --publisher resf --offer rockylinux-x86_64 --plan 9-base
variable "slika" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }
}

variable "slika_ima_plan" {
  description = "false ako slika ne zahtijeva marketplace plan"
  type        = bool
  default     = true
}

# --- Diskovi i pohrana ---
variable "velicina_podatkovnog_gb" {
  type    = number
  default = 24
}

variable "kvota_share_gb" {
  description = "Kvota Azure Files share-a za sigurnosne kopije, GB"
  type        = number
  default     = 24
}

variable "broj_moodle_instanci" {
  type    = number
  default = 2

  validation {
    condition     = var.broj_moodle_instanci >= 2 && var.broj_moodle_instanci <= 8
    error_message = "Dozvoljeno je 2 do 8 instanci."
  }
}

# --- Entra ID ---
variable "entra_domena" {
  description = "Domena za UPN; prazno = inicijalna *.onmicrosoft.com domena"
  type        = string
  default     = ""
}
