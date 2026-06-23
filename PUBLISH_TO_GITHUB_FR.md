# Publication de RendezR LAN sur GitHub

1. Crée un dépôt public ou privé nommé `rendezr` dans l’organisation ou le compte `QuentinLamboley`.
2. Décompresse l’archive fournie.
3. Dépose **le contenu du dossier extrait** à la racine du dépôt, sans créer de sous-dossier supplémentaire.
4. Vérifie que `DESCRIPTION`, `R/`, `README.md` et `.github/` sont directement à la racine.
5. Fais un premier commit puis un push sur la branche `main`.
6. Consulte l’onglet **Actions** : le workflow `R-CMD-check` exécutera les contrôles sous Linux, macOS et Windows.
7. Crée une release GitHub `v0.2.0` lorsque les contrôles sont verts ; attache éventuellement l’archive `rendezr_0.2.0.tar.gz`.

L’installation finale sera :

```r
remotes::install_github("QuentinLamboley/rendezr")
```

Avant publication, relis `README.md`, `PRIVACY.md` et `SECURITY.md`. Le package réalise une découverte active, volontaire et limitée d’un réseau local ; les limites de confidentialité et les règles d’usage doivent rester visibles.
