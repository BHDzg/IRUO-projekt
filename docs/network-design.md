# Objasnjenje mreznih postavki

## OpenStack

* **Adresni plan**: baza `10.77.0.0/16`; mgmt `10.77.0.0/24`; programeri dobivaju
  `/24` od `10.77.100.0/24` nadalje, deterministicki (abecedno po korisnickom
  imenu) — ponovna pokretanja ne mijenjaju adrese.
* **Usmjernik po programeru**: SNAT prema vanjskoj mrezi daje izlaz na internet
  bez javnih adresa; nepostojanje zajednicke L3 tocke = izolacija.
* **Sigurnosne grupe** (stateful, default deny ingress):
  `sg-pristupnik` 22/tcp s 0.0.0.0/0 (jedino javno pravilo);
  `sg-voditelj` 22/tcp samo iz mgmt mreze;
  `sg-moodle` 22, 80 i ICMP samo iz vlastite podmreze.
* **Voditeljev multi-NIC bez forwardinga**: `net.ipv4.ip_forward=0` garantira da
  racunalo voditelja nije most izmedju mreza programera.
* **Floating IP**: tocno jedan, na portu pristupnika.

## Azure

* **Adresni plan**: baza `172.16.0.0/16`; sredisnjica `172.16.0.0/24`, spoke
  mreze `172.16.20.0/24` nadalje; app podmreza je donja polovica (`/25`) sa
  service endpointom `Microsoft.Storage`.
* **Peering**: samo hub↔spoke, `allow_forwarded_traffic=false`; peering nije
  tranzitivan pa spoke↔spoke promet ne postoji ni preko sredisnjice.
* **NSG + ASG**: pravila ciljaju ASG-ove (`asg-pristupnik`, `asg-voditelj`,
  `asg-moodle`) umjesto IP adresa — citljivo i otporno na promjene adresa;
  eksplicitni `Odbij-Ostali-Ulazni` (prioritet 4000) zatvara ostalo.
* **Interni balanser**: privatni frontend; NSG propusta health probe kroz
  servisnu oznaku `AzureLoadBalancer`.
* **Izlaz na internet**: VM-ovi bez javnih adresa; odlazni promet kroz zadani
  odlazni pristup platforme (produkcijsko pobolsanje: NAT Gateway).
