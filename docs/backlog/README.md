# Backlog — Armature

Sujets ouverts sur le kit lui-même (pas sur un projet bootstrapé). Depuis le 2026-07-02, le kit a son propre [`docs/adr/`](../adr/README.md) + [`docs/plans/`](../plans/README.md) (il dogfoode sa propre machinerie) — les décisions structurantes assez mûres y vont ; les décisions plus anciennes gardent leur raisonnement dans `README.md`/`ADAPTING.md`. Le backlog reste pour ce qui n'est pas encore tranché.

## Action manuelle requise (pas automatisable depuis cette session)

_(vide — le seul item de cette section a été traité, voir ci-dessous)_

## Sujets à mûrir

- [ ] **Mode de remplacement de commande (via l'overlay)** — permettre à un overlay `.claude/armature/<nom>.md` de *remplacer* entièrement la commande de base (section `## replace`), pas seulement l'enrichir — pour pouvoir remplacer sous le **nom unique** `/armature:<nom>` au lieu de la commande locale tier (c) et son défaut des deux noms. Écarté par [ADR 0007](../adr/0007-mecanisme-extension-tier-b.md) (extend-seul, 0/6 cas Holoon), mais le besoin UX (nom unique) subsiste. Candidat à un futur ADR. Voir [`command-replacement-mode.md`](command-replacement-mode.md).
- [ ] **Invocation d'une commande par un orchestrateur** — `disable-model-invocation: true` (uniforme sur les 8 skills depuis [ADR 0004](../adr/0004-plugin-armature.md)) **sur-bloque** : il empêche non seulement le déclenchement spontané (voulu), mais aussi le cas légitime « le modèle propose puis lance sur consentement » et surtout le **chaînage depuis un orchestrateur explicitement lancé par l'utilisateur** (`/release` → `/changelog-draft`). Avantage réel du blocage : mince hors distribution tierce + binaire du frontmatter. Pistes : (A) documenter le *follow-inline* des orchestrateurs — zéro-modif, débloque tout de suite ; (B) mode « propose-first » ; (C) exception d'orchestration. Candidat ADR. Déclencheur Holoon (release 26.8.4). Voir [`orchestrated-command-invocation.md`](orchestrated-command-invocation.md).
- [x] **Faire tourner les trois skills pour de vrai** — fait le 2026-07-01/02, sur un vrai projet (`voxtrail`, pas un répertoire jetable vide), par des agents frais suivant le texte des skills à la lettre. Les 3 fonctionnent et n'ont produit aucun résultat incorrect. Voir [`first-real-run-findings.md`](first-real-run-findings.md) : 10 frictions trouvées, 9 corrigées le 2026-07-02 (voir `CHANGELOG.md` § [Unreleased]), 1 laissée volontairement au jugement au cas par cas.
- [x] **Versioning et rétro-propagation** — voir [`versioning-and-retro-propagation.md`](versioning-and-retro-propagation.md). Tampon de version construit (`sha=`/`lang=`/`profile=`/`changelog=` depuis le 2026-07-02) ; remontée cross-projet via `/propose-kit-improvement` ; application sélective via `/pull-kit-updates`. Testé en conditions réelles (item ci-dessus).
- [x] **Modèle de contribution / système d'extension** — voir [`contribution-and-extension-model.md`](contribution-and-extension-model.md). `CONTRIBUTING.md` + `/propose-kit-improvement` couvrent le triage assisté. Le système de plugins/dépôts satellites reste délibérément non construit (zéro contributeur externe à ce jour).

## Fond de tiroir (pas de déclencheur)

- [ ] Profils supplémentaires entre Minimal et Full.
- [ ] Équivalent `.ps1` de `claude.sh` pour Windows natif (hors WSL).

## Fichiers conservés en référence (sujets clos)

- [x] **Personnalisation des commandes par projet (mécanisme d'extension)** — tranché le 2026-07-06 par [ADR 0006](../adr/0006-modele-extension-commandes.md) : modèle à 3 niveaux **sans nouvelle machinerie** — conventions transverses portées par `CLAUDE.md` + `docs/prefs/<login>.md` (déjà auto-chargés), override local assumé (namespace distinct) pour la divergence lourde, overlay à points d'ancrage **délibérément reporté** (wake trigger : customisation additive légère récurrente). Déclencheur : Holoon (6 commandes locales personnalisées). Voir [`command-extension-mechanism.md`](command-extension-mechanism.md) (réflexion source) + [plan](../plans/2026-07-06-modele-extension-commandes.md).
- [x] **Doc de stratégie de test dédiée** — résolu le 2026-07-02 : module `docs/testing.md` (Full only). Voir [ADR 0001](../adr/0001-strategie-de-test.md) + [plan](../plans/2026-07-02-strategie-de-test.md). Déclencheur : le premier run réel des skills.
- [x] **Journal d'incidents / postmortem** — résolu le 2026-07-02 : module `docs/incidents/` (un fichier par incident, Full only), distinct de `lessons-technical.md`. Voir [ADR 0002](../adr/0002-journal-incidents.md) + [plan](../plans/2026-07-02-journal-incidents.md). Déclencheur + premier postmortem : l'incident `settings.json` du 2026-07-01.
