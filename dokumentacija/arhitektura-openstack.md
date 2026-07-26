# OpenStack arhitektura

![OpenStack arhitektura](slike/os-arhitektura.png)

Mermaid izvor (GitHub ga renderira):

```mermaid
flowchart TB
    INET([Internet]) -->|SSH 22| FIP[Floating IP - jedina javna adresa]
    subgraph MGMT[mgmt mreza 10.77.0.0/24]
        PRIST[tslab-t-mgmt-pristupnik]
        VODI[tslab-t-mgmt-voditelj<br/>NIC u svakoj dev mrezi, ip_forward=0]
    end
    FIP --> PRIST -->|SSH| VODI
    subgraph D1[tenant fnovak - 10.77.100.0/24]
        LB1[Octavia balanser<br/>SOURCE_IP persistence] --> A1[moodle-a] & B1[moodle-b]
        A1 & B1 -.-> SW1[(Swift objekti)] & NF1[(Manila sigkopije)]
    end
    subgraph D2[tenant lbabic - 10.77.101.0/24]
        LB2[Octavia balanser] --> A2[moodle-a] & B2[moodle-b]
    end
    VODI -->|SSH| A1 & A2
    D1 x--x|nema komunikacije| D2
```

## Kljucne odluke

* **Izolacija**: svaki programer ima vlastiti Keystone tenant, mrezu, podmrezu i
  usmjernik; medju mrezama programera ne postoji ruta. Voditeljevo racunalo ima NIC
  u svakoj mrezi, ali s iskljucenim IP forwardingom pa nije tranzitna tocka.
* **Izlaz na internet**: usmjernik svakog programera radi SNAT na vanjsku mrezu —
  instance povlace pakete bez javnih adresa.
* **Visoka dostupnost**: dvije Moodle instance (moodle-a, moodle-b) iza internog
  Octavia balansera; ROUND_ROBIN + **SOURCE_IP session persistence** (Moodle drzi
  PHP sesiju lokalno pa isti klijent mora ici na istu instancu) i HTTP nadzor na
  `/status.html`.
* **Dva diska po instanci**: OS disk iz Rocky 9 slike + podatkovni Cinder disk
  (XFS, automatski montiran na `/opt/moodle-podaci`).
