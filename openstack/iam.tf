# =============================================================================
# Keystone IAM — tenanti, korisnici, grupe i role (least-privilege)
#   * svaki programer  -> vlastiti PROJEKT (najjaca granica izolacije)
#   * programer        -> rola member SAMO na svom projektu
#                         (upravljanje i start/stop iskljucivo svojih instanci)
#   * devops voditelj  -> rola admin na svim projektima programera
#                         (paljenje/gasenje svih instanci u sustavu)
# =============================================================================

resource "openstack_identity_project_v3" "tenant" {
  for_each    = local.programeri
  name        = "${local.prefiks}-${each.key}-tenant"
  description = "Izolirani tenant — ${each.value.ime} ${each.value.prezime}"
  tags        = local.oznake_lista
}

resource "openstack_identity_group_v3" "programeri" {
  name        = "${local.prefiks}-skupina-programeri"
  description = "Korisnici s rolom developer"
}

resource "openstack_identity_group_v3" "voditelji" {
  name        = "${local.prefiks}-skupina-voditelji"
  description = "Korisnici s rolom devops_lead"
}

resource "random_password" "lozinka" {
  for_each = local.svi
  length   = 22
  special  = true
}

resource "openstack_identity_user_v3" "racun" {
  for_each           = local.svi
  name               = each.value.nadimak
  password           = random_password.lozinka[each.key].result
  description        = "${each.value.ime} ${each.value.prezime} (${each.value.rola})"
  default_project_id = each.value.voditelj ? null : openstack_identity_project_v3.tenant[each.key].id
}

resource "openstack_identity_user_membership_v3" "clan_programer" {
  for_each = local.programeri
  user_id  = openstack_identity_user_v3.racun[each.key].id
  group_id = openstack_identity_group_v3.programeri.id
}

resource "openstack_identity_user_membership_v3" "clan_voditelj" {
  for_each = local.voditelji
  user_id  = openstack_identity_user_v3.racun[each.key].id
  group_id = openstack_identity_group_v3.voditelji.id
}

# Programer: member iskljucivo na vlastitom tenantu
resource "openstack_identity_role_assignment_v3" "programer_svoj" {
  for_each   = local.programeri
  user_id    = openstack_identity_user_v3.racun[each.key].id
  project_id = openstack_identity_project_v3.tenant[each.key].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# Voditelj: admin na svakom tenantu programera
locals {
  voditelj_x_programer = merge([
    for v in keys(local.voditelji) : {
      for p in keys(local.programeri) : "${v}~${p}" => { voditelj = v, programer = p }
    }
  ]...)
}

resource "openstack_identity_role_assignment_v3" "voditelj_svi" {
  for_each   = local.voditelj_x_programer
  user_id    = openstack_identity_user_v3.racun[each.value.voditelj].id
  project_id = openstack_identity_project_v3.tenant[each.value.programer].id
  role_id    = data.openstack_identity_role_v3.admin.id
}
