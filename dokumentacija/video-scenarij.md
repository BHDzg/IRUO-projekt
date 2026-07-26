# Scenarij za video (YouTube, privatno): izvrsavanje pokreni.sh

**Trajanje:** 6–9 min · **Alat:** OBS / snimka ekrana s mikrofonom
**Priprema:** povecan font terminala, `clear`, otvoren GitHub repo u pregledniku.
Dugi `apply` (Octavia zna trajati) snimi pa ubrzaj 2–4× u montazi.

## 1. Uvod (30 s) — pokazi README na GitHubu
> „U ovom videu pokrecem deploy skriptu projekta ts-moodle-lab: automatizirano
> kreiranje izoliranih Moodle testnih okolina u OpenStacku i Azureu, Terraformom.
> Sve pokrece jedna skripta koja prima CSV s korisnicima."
Pokazi i karticu *Commits* (redovito pohranjivanje u git).

## 2. Struktura i CSV (60–90 s)
```bash
tree -L 2
cat podaci/tim.csv
```
> „Skripta pokreni.sh je jedina ulazna tocka. CSV ima jednog devops leada i dva
> developera. Skripta ga awk-om pretvara u korisnici.auto.tfvars.json, a
> Terraform kroz for_each za svakog developera instancira modul okolina —
> mreza, sigurnosne grupe, dvije instance s dva diska, balanser i dvije pohrane.
> Dodam li redak u CSV, sljedece pokretanje kreira i tu okolinu."
Pokazi kratko `openstack/lokali.tf` (korisnicko ime = prvo slovo + prezime).

## 3. Validacija (45 s)
```bash
./pokreni.sh -h
./pokreni.sh podaci/tim.csv
printf 'ime;prezime;rola\npero;peric;hacker\n' > /tmp/los.csv && ./pokreni.sh /tmp/los.csv
```
> „Zadana akcija je provjera: validira se CSV — zaglavlje, role, tocno jedan
> lead — pa terraform validate za oba oblaka. Neispravna rola se odbija."

## 4. OpenStack deploy (2–3 min, srz videa — objasni STO radi)
```bash
source ~/openrc
./pokreni.sh -c openstack -a primjena podaci/tim.csv
```
> „Nastaje redom: Keystone sloj — tenant po programeru, racuni iz CSV-a, skupine,
> rola member programeru na vlastitom tenantu i admin voditelju na svima. Zatim
> mgmt mreza s pristupnikom — jedinom masinom s javnom, floating adresom — i
> racunalo voditelja s karticom u mrezi svakog programera, ali s iskljucenim IP
> forwardingom. Za svakog developera: izolirana mreza s vlastitim usmjernikom za
> izlaz na internet, sigurnosna grupa koja SSH i HTTP dopusta samo unutar
> podmreze, instance moodle-a i moodle-b s OS i podatkovnim diskom, Octavia
> balanser sa SOURCE_IP persistencijom — jer Moodle drzi sesiju lokalno — te
> Swift spremnik i Manila NFS s pristupom ogranicenim na tenant i podmrezu."
```bash
terraform -chdir=openstack output
```

## 5. Dokaz (60–90 s)
```bash
ssh -J rocky@<JAVNA_IP> rocky@<IP_VODITELJA>
ssh rocky@<IP_MOODLE_A>
df -h | grep -E 'moodle|sigkopije'
curl http://<VIP_BALANSERA>/status.html
```
> „Pristup iskljucivo kroz pristupnik. df pokazuje automatski montiran
> podatkovni disk i NFS za sigurnosne kopije; balanser vraca OK."
Opcionalno Horizon: prijava kao fnovak → vidi samo svoj tenant, Start/Stop radi.

## 6. Azure deploy (1,5–2 min, ubrzano)
```bash
./pokreni.sh -c azure -a primjena podaci/tim.csv
```
> „Ista skripta, isti CSV. Nastaje hub-and-spoke: sredisnjica s pristupnikom i
> voditeljem, po programeru vlastita resource grupa i VNet peeran samo na hub.
> NSG pravila ciljaju ASG-ove. Blob pohrani VM pristupa managed identityjem, bez
> kljuceva; Files share se SMB-om montira za sigurnosne kopije. Custom RBAC rola
> upravljac-napajanja daje developeru samo start, restart, powerOff i deallocate,
> iskljucivo na njegovoj resource grupi."
Portal: resource grupe `tslab-t-*`, tagovi, IAM kartica; prijava kao fnovak →
vidi samo svoju RG, Stop radi, Delete ne.

## 7. Zavrsetak (20 s)
> „Jedna skripta, jedan CSV, dva oblaka — kompletna izolirana infrastruktura za
> proizvoljan broj programera. Kod i dokumentacija su u repozitoriju. Hvala!"
Opcionalno: `./pokreni.sh -c oba -a rusenje podaci/tim.csv`

## Nakon snimanja
- [ ] YouTube: **Private** (ili Unlisted po uputama), link u opis → repo
- [ ] Link videa u README i dokumentaciju
- [ ] Provjeri: pokretanje + objasnjenje + uspjesan zavrsetak su u kadru
