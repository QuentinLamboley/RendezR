# RendezR LAN — documentation française

RendezR LAN permet à des personnes ayant **expressément activé** le package sur le **même réseau local privé** d’être appariées au hasard puis d’échanger de courts messages depuis la console R/RStudio.

Il n’y a ni domaine, ni serveur public, ni compte, ni cloud, ni télémétrie. Chaque participant lance temporairement un petit point d’écoute sur son propre ordinateur. La découverte est volontaire, limitée au sous-réseau IPv4 privé choisi et ne démarre jamais au chargement du package.

> « Sans serveur » signifie ici **sans serveur central ou public**. Chaque participant exécute néanmoins un point d’écoute local éphémère afin que son correspondant puisse lui livrer un message directement.

## Démarrage

```r
install.packages(c("cli", "curl", "digest", "fs", "httpuv", "jsonlite", "later", "rappdirs", "uuid"))
install.packages("remotes")
remotes::install_github("QuentinLamboley/rendezr")

library(rendezr)
rr_terms()
rr_accept_rules(accept = TRUE)
rr_lan_start()
rr_lan_find()
rr_send("Bonjour !")
```

Tous les participants doivent utiliser le même réseau local IPv4, le même port (47831 par défaut) et le même salon (`general` par défaut). Les réseaux invités, les VLAN séparés et l’isolation Wi-Fi peuvent empêcher la découverte.

## Limites importantes

- La version 0.2.0 échange les messages en HTTP local, **sans chiffrement de bout en bout**.
- N’envoyez jamais de données personnelles, confidentielles, médicales, financières, d’identifiants, ni de données de recherche sensibles.
- Lorsqu’un pare-feu le demande, autorisez R/RStudio uniquement sur le profil **réseau privé**. Ne créez jamais de redirection de port depuis Internet.
- La découverte est déclenchée uniquement par `rr_lan_discover()` ou `rr_lan_find()` et elle se limite par défaut à 254 adresses privées potentielles.

Voir [README.md](README.md) pour les commandes et [PRIVACY.md](PRIVACY.md) pour le détail.
