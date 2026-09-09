---
status: implemented
created: 2026-09-09
settled: 2026-09-09
related-adr: 0008
---

# Plan — Récolte du contexte hors-code au bootstrap (compagnon de l'ADR 0008)

Compagnon de [l'ADR 0008](../adr/0008-recolte-contexte-bootstrap.md). Capture *comment* la Phase 3 a été insérée dans `plugin/skills/bootstrap/SKILL.md`, ce qui a été écarté, et ce qui reste ouvert.

## Reformulation du problème

Un seul fichier est concerné : `plugin/skills/bootstrap/SKILL.md` (138 lignes avant la modification, 7 phases après). Aucun template `en`/`fr` n'est touché — donc pas de contrainte de parité, mais `tools/lint-templates.py` reste à faire tourner pour vérifier qu'on n'a rien cassé par ailleurs.

Contrainte structurelle : la récolte doit se produire **après** l'analyse de code (elle en réutilise le contexte) et **avant** les questions de cadrage (une note externe pré-remplit souvent le nom, le one-liner et la stack mieux que le code) — donc entre les Phases 2 et 3 existantes, ce qui impose un renumérotage de la moitié du fichier et de toutes ses références croisées internes.

## Forme cible

```
Phase 2  Analyse du code (inchangée)
   ↓
Phase 3  RÉCOLTE  ── conversation en cours ─┐
   │              ── documents désignés ────┤→ tri/filtre → shortlist → confirmation
   │              ── git log ───────────────┘
   ↓
Phase 4  Questions de cadrage (pré-remplies par 2 ET 3)
   ↓
Phase 5  Génération (+ § « Seeding from Phase 3 » : n'écrit que le confirmé)
   ↓
Phase 6  Git · Phase 7  Résumé (+ ligne « ce que la récolte a produit »)
```

## Surface d'impact

### Skill
`plugin/skills/bootstrap/SKILL.md` : nouvelle Phase 3 ; renumérotage 3→4, 4→5, 5→6, 6→7 (titres + ~25 références internes, dont « Phases 1-4 » → « Phases 1-5 ») ; sortie de la Phase 2 redirigée vers la Phase 3 ; § *Seeding from Phase 3* en Phase 5 ; ligne de résumé en Phase 7 ; garde ajoutée dans *What this skill does NOT do*.

### Templates
Aucun. Parité `en`/`fr` intacte.

### Documentation
`ADAPTING.md` (section consommateur), `CHANGELOG.md` § `[Unreleased]`, index `docs/adr/README.md` + `docs/plans/README.md`, paragraphe d'état de `CLAUDE.md`.

## Lots d'implémentation

### Lot 1 — Insérer la Phase 3 dans le skill
- Renumérotage des phases + reciblage du saut de la Phase 2.
- Rédaction de la phase : les 3 sources ordonnées par richesse, le filtre et son routage (lessons / backlog / ADR `accepted`), la clause « proposer, jamais écrire ».
- **Critère de sortie** : les 4 gardes de l'ADR sont chacune littéralement présentes dans le texte de la phase, et aucune référence « Phase N » du fichier ne pointe dans le vide.

### Lot 2 — Câbler la récolte dans les phases suivantes
- Phase 4 : pré-remplissage depuis la Phase 3 annoncé dans la phrase d'intro.
- Phase 5 : § *Seeding from Phase 3* — format d'écriture pour chacune des trois destinations, suppression de l'entrée-gabarit de `lessons-technical.md` dès qu'il y a du vrai contenu, cas « backlog externe » traité (liste à coller, pas de `docs/backlog/`).
- Phase 7 : ce que la récolte a produit, ou explicitement « rien à récolter ».
- **Critère de sortie** : un exécutant qui suit le texte sait exactement où et sous quelle forme écrire chaque item confirmé.

### Lot 3 — Doctrine et traçabilité
- ADR 0008 + ce plan + les deux index.
- `ADAPTING.md` § *Matière hors-code au bootstrap*.
- `CHANGELOG.md` § `[Unreleased]`.
- **Critère de sortie** : `python3 tools/lint-templates.py` passe.

### Lot 4 (gated future) — Valider la Phase 3 par un run réel
- Faire tourner `/armature:bootstrap` par un agent frais sur un vrai projet, dans une session qui a *réellement* travaillé avant, et vérifier que la récolte produit une shortlist honnête (ni vide, ni gonflée).
- **Déclencheur de réveil** : le prochain bootstrap réel sur un projet neuf — à faire dans la même passe que le test end-to-end de `/armature:bootstrap` que `CLAUDE.md` signale encore comme restant.

## Alternatives considérées (plus détaillé que l'ADR)

### α — Ne pas renuméroter : glisser la récolte en « Phase 2 bis »
Écartée : le fichier n'a pas d'autre demi-phase, et la numérotation est le seul repère de séquence pour un exécutant qui lit linéairement. Le coût du renumérotage est ponctuel ; celui d'une numérotation bancale est permanent.

### β — Placer la récolte *après* les questions de cadrage
Écartée : c'est justement la matière hors-code (une note de projet externe) qui donne les meilleures réponses au cadrage. Récolter après aurait fait poser des questions dont la réponse était déjà dans un document non lu.

### γ — Fusionner la question « documents externes » dans le lot `AskUserQuestion` de la Phase 4
Écartée pour la même raison : la réponse doit être exploitée *avant* le cadrage. Le tour d'interaction supplémentaire est le prix de l'ordre correct.

### δ — Lire le transcript sur disque plutôt que le contexte de session
Écartée : inutile ici — le skill s'exécute *dans* la session concernée, il a déjà la conversation sous les yeux. Le `transcript_path` n'a de sens que pour le hook `SessionEnd`, qui s'exécute après extinction.

## Questions ouvertes

- ~~**Q1 — ADR ou item de backlog ?**~~ : résolue à l'ouverture — changement de comportement d'un skill livré avec des gardes à geler ⇒ ADR (voir *Alternatives* de l'ADR 0008).
- ~~**Q2 — faut-il un plan compagnon pour une ADR implémentée dans la foulée ?**~~ : résolue — oui, c'est déjà le régime des ADR 0001/0002/0003/0007 du kit (plan `implemented` daté du jour). La règle « pas de plan compagnon » que le skill énonce vise les décisions **du projet bootstrapé** déjà implémentées *avant* le bootstrap, pas ce cas-ci.
- **Q3 — la récolte doit-elle savoir alimenter `docs/incidents/` ?** : laissée ouverte. Une session peut contenir un vrai incident (action destructrice, panne) ; le routage actuel l'enverrait en leçon. Pas de cas réel observé au bootstrap à ce jour — à traiter si ça se présente, pas avant.

## Progression

| Lot | SHA | Date | Notes |
|---|---|---|---|
| Lot 1 — Phase 3 dans le skill | *(cette passe)* | 2026-09-09 | Renumérotage 3→7 + phase rédigée |
| Lot 2 — Câblage phases 4/5/7 | *(cette passe)* | 2026-09-09 | Pré-remplissage, *Seeding*, résumé, garde |
| Lot 3 — Doctrine | *(cette passe)* | 2026-09-09 | ADR 0008, ce plan, `ADAPTING.md`, `CHANGELOG.md`, index |
| Lot 4 — Run réel | — | — | Gated future (déclencheur : prochain bootstrap réel) |

## Follow-ups surfacés pendant l'implémentation

- **Routage d'un incident vécu en session (Q3)** — pas de destination créée ; à rouvrir si un bootstrap rencontre le cas. Reste dans ce plan, pas d'item de backlog dédié (aucun déclencheur observé).
- **Validation par agent frais** — porté par le Lot 4 gated future, à mutualiser avec le test end-to-end de `/armature:bootstrap` encore en attente (`CLAUDE.md` § *Where things stand*).

## Journal de décisions

- **2026-09-09** — récolte placée *avant* le cadrage plutôt qu'après : la matière hors-code pré-remplit les questions, l'inverse aurait fait poser des questions déjà répondues ailleurs.
- **2026-09-09** — ADR générées en `accepted` uniquement, jamais `proposed` : une ADR `proposed` créée par une machine sur une décision non tranchée est une dette, pas une trace. Le cas « pas encore tranché » est déjà couvert par le backlog.
- **2026-09-09** — le filtre `lessons-technical` n'est **pas** rejoué ni reformulé dans le bootstrap : il pointe vers celui de `/armature:capture-lessons`. Deux formulations du même critère divergeraient.

## Prochaines actions

- [x] Phase 3 rédigée et câblée dans les phases suivantes.
- [x] ADR 0008 + ce plan + index à jour.
- [x] `ADAPTING.md` et `CHANGELOG.md` à jour.
- [x] `python3 tools/lint-templates.py` au vert.
- [ ] *(gated future)* Lot 4 — run réel par un agent frais sur un projet neuf.
