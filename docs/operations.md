# Operations

Setup, build, run, debug, déploiement pour Armature. **Document vivant** — à mettre à jour au fil de l'évolution de l'outillage. Voir [`ADAPTING.md`](../ADAPTING.md) pour le pourquoi de chaque choix non évident du kit.

## Prérequis

- **Claude Code** installé et dans le `PATH` (c'est l'unique « runtime » du projet).
- **Python 3** (stdlib uniquement — aucun paquet à installer) pour `tools/lint-templates.py`.
- **Bash** et **git**.
- Aucun compte ni accès particulier pour développer. Pour *publier* une release : droit de push sur `github.com/Plasma-AndraaX/armature`.

## Setup

Il n'y a **rien à installer** : pas de gestionnaire de paquets, pas de dépendances, pas d'étape de génération.

```bash
git clone https://github.com/Plasma-AndraaX/armature.git
cd armature
python3 tools/lint-templates.py   # vérifie que le clone est sain
```

## Build

```bash
# Aucun build. Le « livrable » est le contenu de plugin/, consommé tel quel
# par Claude Code via le marketplace ou via --plugin-dir.
```

## Run (développement local)

```bash
./claude.sh          # = claude --plugin-dir ./plugin
```

Lance Claude Code avec le plugin chargé **depuis le working tree**, de sorte que les vraies commandes `/armature:*` s'exécutent sur leur source réelle (dispatch d'overlay compris). Après une édition d'un `plugin/skills/<x>/SKILL.md` : `/reload-plugins`.

> Ne **pas** installer le plugin depuis un marketplace dans ce dépôt : l'install copie un snapshot en cache et masque les éditions du working tree (deux copies divergentes). Voir `lessons-technical.md`.

## Test

```bash
python3 tools/lint-templates.py
```

C'est le seul contrôle automatisé. Le reste est manuel : un run réel de bout en bout des skills sur un vrai projet. Pour la *stratégie* de test (niveaux, philosophie, ce qu'on ne teste pas), voir [`testing.md`](testing.md) — ici, seulement le *comment lancer*.

## Debug

- **Le linter** imprime un rapport et sort en non-zéro ; il rend chaque gabarit pour chaque combinaison (changelog × memoryhook), donc un échec nomme la combinaison fautive.
- **Un skill qui se comporte mal** ne se debugge pas au débogueur : c'est du prompt. Éditer le `SKILL.md`, `/reload-plugins`, relancer — ou faire tourner un agent frais sur le texte du skill pour voir ce qu'il en comprend sans contexte.
- **Hook `SessionEnd`** : son stdout n'est jamais affiché ; les traces vont dans `tools/session-end-capture.log` (gitignored).

## Déploiement / Release

Séquence à la main, dans cet ordre :

1. `plugin/.claude-plugin/plugin.json` → bumper `version`. **C'est ce champ qui pilote la détection d'update côté consommateur** ; `VERSION` n'est que cosmétique.
2. `VERSION`, `README.md`, `CLAUDE.md` → aligner le numéro affiché.
3. `CHANGELOG.md` → rouler `[Unreleased]` en une section datée.
4. `python3 tools/lint-templates.py`, puis commit `release: X.Y.Z`, tag `vX.Y.Z`, push sur `master`.
5. Côté projet consommateur : `/plugin marketplace update armature` **avant** `/plugin update` — sinon on réinstalle une version périmée sans aucune erreur. Pour un plugin installé en scope projet, passer par la CLI : `claude plugin update armature@armature --scope project`.

## Pièges connus

Voir [`lessons-technical.md`](lessons-technical.md) pour les pièges spécifiques à l'environnement, au fil de leur découverte. Les deux entrées actuelles couvrent précisément les hooks `SessionEnd` et la mécanique de publication du plugin.
