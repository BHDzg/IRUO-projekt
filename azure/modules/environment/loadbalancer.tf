# =============================================================================
# INTERNI Azure Standard Load Balancer ispred Moodle VM-ova.
#   * frontend je privatna adresa u app podmrezi (nije javno dostupan)
#   * load_distribution = SourceIP: Moodle sesija je lokalna instanci, pa isti
#     klijent uvijek zavrsava na istoj instanci (session affinity)
# Usporedba s Application Gatewayem: vidi dokumentaciju (usporedba elemenata).
# =============================================================================

resource "azurerm_lb" "balanser" {
  name                = "${var.prefiks}-${var.vlasnik}-balanser"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  tags                = local.meta

  frontend_ip_configuration {
    name                          = "prednji"
    subnet_id                     = azurerm_subnet.aplikacija.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "moodle" {
  name            = "${var.prefiks}-${var.vlasnik}-balanser-bazen"
  loadbalancer_id = azurerm_lb.balanser.id
}

resource "azurerm_lb_probe" "http" {
  name                = "${var.prefiks}-${var.vlasnik}-balanser-nadzor"
  loadbalancer_id     = azurerm_lb.balanser.id
  protocol            = "Http"
  port                = 80
  request_path        = "/status.html"
  interval_in_seconds = 12
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "${var.prefiks}-${var.vlasnik}-balanser-http"
  loadbalancer_id                = azurerm_lb.balanser.id
  frontend_ip_configuration_name = "prednji"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.moodle.id]
  probe_id                       = azurerm_lb_probe.http.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  load_distribution              = "SourceIP"
  disable_outbound_snat          = true
}

resource "azurerm_network_interface_backend_address_pool_association" "moodle" {
  for_each                = local.instance
  network_interface_id    = azurerm_network_interface.moodle[each.key].id
  ip_configuration_name   = "glavna"
  backend_address_pool_id = azurerm_lb_backend_address_pool.moodle.id
}
