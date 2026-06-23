# Installation et utilisation de RendezR LAN

## 1. Installer depuis GitHub

```r
install.packages(c("cli", "curl", "digest", "fs", "httpuv", "jsonlite", "later", "rappdirs", "uuid", "remotes"))
remotes::install_github("QuentinLamboley/rendezr")
```

Puis :

```r
library(rendezr)
rr_terms()
rr_accept_rules(accept = TRUE)
rr_lan_start()
```

## 2. Installation locale depuis une archive

```r
install.packages(c("cli", "curl", "digest", "fs", "httpuv", "jsonlite", "later", "rappdirs", "uuid"))
install.packages("rendezr_0.2.0.tar.gz", repos = NULL, type = "source")
library(rendezr)
```

## 3. Usage à deux ordinateurs

Sur les deux ordinateurs, connectés au même réseau local privé :

```r
library(rendezr)
rr_accept_rules(accept = TRUE)
rr_lan_start()
```

Sur l’un des deux :

```r
rr_lan_find()
rr_send("Bonjour !")
```

L’autre personne voit le message dans sa console lorsque R est au repos. Pendant un calcul long, elle peut appeler régulièrement :

```r
rr_pump()
```

## 4. Cas d’un réseau avec plusieurs interfaces ou VPN

```r
rr_lan_start(
  address = "192.168.1.42",
  subnet = "192.168.1.0/24",
  port = 47831,
  room = "general"
)
```

Les deux personnes doivent utiliser le même port et le même salon. Le package limite volontairement la découverte aux CIDR privés /16 à /30 et refuse les scans automatiques supérieurs à 254 hôtes.

## 5. Pare-feu

Windows ou macOS peut demander une autorisation réseau lors du premier appel à `rr_lan_start()`. Autorisez seulement les **réseaux privés**. N’ajoutez aucune règle de transfert de port sur votre box ou routeur.

## 6. Arrêter complètement

```r
rr_lan_stop()
```

Cela ferme le point d’écoute local et retire cette session R de la découverte.
