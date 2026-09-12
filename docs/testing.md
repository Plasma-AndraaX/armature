# Stratégie de test — Armature

*Comment* le kit se teste : la **doctrine**, pas seulement les commandes. Le kit n'a pas d'`operations.md` séparé (il est petit et mono-outil) — le *comment lancer* tient dans la dernière section.

## Philosophie

Le kit est un arbre de templates + des skills en Markdown. Il n'a **pas de code applicatif** à tester unitairement. Sa correction tient à deux choses : (1) que les templates *rendent* proprement dans toutes les combinaisons profil × changelog × langue, et (2) que les skills, *lus par un LLM*, produisent réellement le comportement décrit. La vérification est donc **un lint mécanique + un run manuel end-to-end** — pas une suite de tests automatisés. Compromis assumé tant que le kit reste petit, solo, et sans CI.

## Niveaux de test

| Niveau | Outil | Périmètre | Quand |
|---|---|---|---|
| Lint des templates | `python3 tools/lint-templates.py` | Balance des marqueurs `FULL`/`MINIMAL`/`CHANGELOG`, parité `en`/`fr`, rendu sans placeholder / marqueur / ligne-vide-de-tableau résiduels sur chaque profil × changelog | Avant chaque commit touchant `plugin/templates/`, un skill, ou le lint lui-même |
| Run manuel end-to-end | Session Claude Code réelle | Que les skills `/armature:*` (`bootstrap`, `new-adr`, `capture-lessons`…) produisent réellement le comportement décrit, sur un vrai projet | À chaque changement substantiel d'un skill |

Le run manuel end-to-end n'est pas de la cérémonie théorique : le premier (2026-07-01/02, sur le projet `voxtrail`) a fait remonter 10 frictions que le lint ne pouvait pas voir — voir [`backlog/first-real-run-findings.md`](backlog/first-real-run-findings.md).

## Ce qu'on ne teste pas (délibérément)

- **Pas de CI** — le lint tourne à la main. Projet solo à cadence irrégulière ; une CI serait de la cérémonie non tenue (cohérent avec la doctrine « ne pas construire au-delà d'un besoin démontré »).
- **Pas de test unitaire du Python de `lint-templates.py`** — outil de ~150 lignes, vérifié par son propre usage : s'il se trompait, un rendu cassé passerait, ce qui se verrait au bootstrap réel suivant.
- **Pas de golden-file du rendu** — le lint vérifie l'*absence d'anomalie*, pas l'égalité à une sortie figée, pour pouvoir faire évoluer la prose sans casser un golden à chaque phrase.

## Définition de « testé »

Un changement est « testé » avant commit si :
- **Changement de template** → `lint-templates.py` est vert.
- **Changement de skill** (`.claude/commands/*.md` ou `plugin/templates/*/dot-claude/commands/*.md`) → idéalement un run réel du skill concerné ; à défaut, une relecture à la lettre de son chemin d'exécution. **Le lint ne couvre pas la *sémantique* d'un skill** — c'est précisément le trou que le run manuel comble.

## Comment lancer

```bash
python3 tools/lint-templates.py
```

Le run manuel end-to-end n'a pas de commande unique : ouvrir Claude Code dans un projet cible (jetable ou réel) et invoquer les skills. Voir [`backlog/first-real-run-findings.md`](backlog/first-real-run-findings.md) pour la méthodologie du premier run.

**Dogfooding du kit lui-même** — pour exercer les vraies `/armature:*` sur *leur propre source* (dispatch d'overlay compris), lancer le kit avec son plugin chargé depuis le working tree :

```bash
./claude.sh          # = claude --plugin-dir ./plugin
```

Éditer `plugin/skills/<x>/SKILL.md` puis `/reload-plugins` recharge à chaud — dans cet ordre, et **à chaque** lot d'éditions : un reload ne charge qu'un instantané, et le texte injecté peut ensuite contredire le disque en silence (voir `lessons-technical.md`). **Ne pas** installer le plugin via un marketplace dans ce repo : ça copierait un snapshot en cache et masquerait tes éditions (deux copies divergentes). Le `--plugin-dir` est *la* voie live confirmée par la doc Claude Code.
