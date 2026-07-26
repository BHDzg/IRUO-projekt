# Azure arhitektura (hub-and-spoke)

![Azure arhitektura](images/azure-architecture.png)

```mermaid
flowchart TB
    INET([Internet]) -->|SSH 22 - NSG: samo asg-pristupnik| PIP[Public IP]
    subgraph HUB[sredisnjica tslab-t-mgmt-rg - 172.16.0.0/24]
        PIP --> J[pristupnik B1s]
        J -->|SSH| V[voditelj B1s]
    end
    subgraph S1[spoke tslab-t-fnovak-rg - 172.16.20.0/24]
        L1[interni balanser<br/>SourceIP affinity] --> M1[moodle-a B2s] & M2[moodle-b B2s]
        M1 & M2 -.-> SA1[(storage: blob objekti + files sigkopije)]
    end
    subgraph S2[spoke tslab-t-lbabic-rg - 172.16.21.0/24]
        L2[interni balanser] --> M3[moodle-a] & M4[moodle-b]
    end
    HUB <-->|peering, forwarded OFF| S1 & S2
    S1 x--x|nema peeringa| S2
    V -->|SSH kroz peering| M1 & M3
```

## Kljucne odluke

* **Hub-and-spoke**: spoke VNet-ovi peerani su iskljucivo na sredisnjicu;
  `allow_forwarded_traffic=false` + nepostojanje spoke-spoke peeringa znaci da
  promet izmedju programera nije moguc (peering nije tranzitivan).
* **Javna izlozenost**: Public IP postoji samo na pristupniku; NSG pravilo
  `Dozvoli-Internet-SSH-SamoPristupnik` cilja ASG, ne IP adrese.
* **Pohrana**: po programeru jedan storage account — blob spremnik `objekti`
  (pristup managed identityjem + rola samo na tom accountu) i file share
  `sigkopije` (SMB mount, mrezno ogranicen service endpointom).
* **Balanser**: interni Standard LB s `load_distribution = SourceIP`
  (session affinity za Moodle) i probeom na `/status.html`.
