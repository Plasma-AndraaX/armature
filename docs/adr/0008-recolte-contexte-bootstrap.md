---
status: accepted
date: 2026-09-09
deciders: [Plasma-AndraaX]
superseded-by:
related-adrs: []
related-plans: [2026-09-09-recolte-contexte-bootstrap]
---

# ADR 0008 — Récolter le contexte hors-code au bootstrap (conversation, documents externes, historique git)

## Contexte

Le skill `/armature:bootstrap` suppose que **toute la matière utile est dans le repo**. Sa Phase 2 est sérieuse sur le code (manifests, sources échantillonnées, scripts, CI, TODO, hétérogénéité de style, agents `Explore`) — mais elle ne regarde que ça. Constat vérifiable : dans `plugin/skills/bootstrap/SKILL.md`, le mot « transcript » n'apparaissait qu'une fois, pour le hook `SessionEnd`, donc pour les sessions *futures*. Rien ne lisait la conversation **en cours** pendant le bootstrap.

Conséquence structurelle : trois répertoires sortaient systématiquement vides — `docs/lessons-technical.md` (son seul gabarit), `docs/backlog/` (sauf le triage opt-in des TODO du code) et `docs/adr/` (les ADR n'étaient qu'un « prochain pas » du résumé final).

Or, au moment où on bootstrappe, l'essentiel vient d'être dit : bootstrap réel du **2026-09-09** sur un projet Node (~900 lignes, 4 commits d'historique). Ont été écrits **à la main, après coup**, uniquement parce que la conversation était encore en contexte : **3 ADR** pour des décisions déjà tranchées et argumentées, **6 leçons techniques** réellement rencontrées pendant la session, **8 items de backlog** issus de fonctionnalités demandées à l'oral. Aucun de ces 17 artefacts ne serait sorti du bootstrap ; lancé dans une session fraîche, il aurait produit trois répertoires vides et cette matière aurait été perdue à l'extinction de la session.

Trois sources manquaient, par ordre de richesse : **la conversation en cours** (la seule qui disparaît si on ne la capture pas maintenant), **les documents hors repo que l'utilisateur désigne** (dans le cas vécu, une note externe contenait déjà tout le « pourquoi » de l'outil, alternatives écartées comprises — de la matière d'ADR prête à l'emploi), et **l'historique git** quand il existe.

## Décision

Ajouter à `/armature:bootstrap` une **Phase 3 « Harvest the surrounding context »**, intercalée entre l'analyse de code (Phase 2) et les questions de cadrage (désormais Phase 4), qui va chercher cette matière **avant** de générer et alimente `docs/lessons-technical.md`, `docs/backlog/` et — quand une décision est visiblement **déjà tranchée et argumentée** — une ADR en `status: accepted`, jamais un `proposed` vide.

Quatre gardes sont **figées par cet ADR** (elles sont déjà la doctrine du kit ailleurs) :

1. **Proposer, jamais écrire en silence** — shortlist groupée par destination, avec la source de chaque candidat et la queue de ce qui a été filtré ; l'utilisateur confirme item par item, comme pour le triage des TODO.
2. **Le filtre compte plus que la collecte** — le critère de `lessons-technical.md` reste inchangé (> 30 min perdues par le prochain, vrai indépendamment du lecteur, actionnable, non dérivable du code). Une conversation est majoritairement du bavardage.
3. **Étape non obligatoire** — sources sondées à bas coût ; rien à récolter ⇒ une ligne et on passe. Un bootstrap en session fraîche reste aussi rapide qu'avant.
4. **Demander pour les documents externes** — ne jamais supposer ni partir en chasse hors du répertoire cible ; l'utilisateur nomme les chemins.

## Conséquences

- **Positives** — les trois répertoires les plus structurants du kit ne naissent plus vides sur un vrai projet. La matière la plus périssable (la conversation en cours) est capturée au seul moment où elle est encore accessible. Une note de projet externe, souvent déjà écrite, devient exploitable au lieu d'être ignorée. Le bootstrap devient cohérent avec le reste du kit : `/armature:capture-lessons` sait déjà lire « la conversation en cours », le bootstrap était le seul à l'ignorer.
- **Négatives** — une phase de plus dans un skill déjà long (renumérotage 3→4, 4→5, 5→6, 6→7 inclus), et un tour d'interaction supplémentaire quand il y a de la matière. Le jugement de « tranché et argumenté » vs « en suspens » est prompt-level, donc mou : un exécutant complaisant peut produire une ADR `accepted` sur une décision qui ne l'était pas — d'où la confirmation utilisateur obligatoire. Le risque d'aspiration reste réel si le filtre est mal appliqué.
- **Neutres** — aucun template touché (`en`/`fr` inchangés, parité intacte) : la modification est entièrement dans le skill. Le hook `SessionEnd` d'auto-capture est orthogonal — il couvre les sessions *suivantes* ; cet ADR couvre la session du bootstrap lui-même.

## Alternatives considérées

- **Item de backlog plutôt qu'ADR** — écarté : c'est un changement de comportement d'un skill livré, avec des gardes qu'on veut geler (proposer sans écrire, filtre inchangé, non-obligatoire). Le backlog sert à ce qui n'est pas encore tranché ; ici la décision l'était.
- **S'en remettre au hook `SessionEnd`** — écarté : ce hook capture la session *écoulée* d'un projet **déjà bootstrapé**. Au moment du bootstrap il n'existe pas encore, et la matière de la session en cours n'a aucune destination.
- **Rendre la récolte obligatoire (toujours poser les questions)** — écarté : casserait le bootstrap en session fraîche, cas le plus fréquent au démarrage d'un projet vide.
- **Tout verser sans filtre, quitte à élaguer ensuite** — écarté : un bootstrap qui déverse la conversation dans les docs est pire qu'un bootstrap qui livre des fichiers vides ; il détruit la valeur de `lessons-technical.md` dès le premier jour.
- **Générer les ADR en `status: proposed`** — écarté : une ADR `proposed` vide est une dette, pas une trace. Une décision encore en suspens est un item de backlog ; seule une décision réellement tranchée et argumentée devient une ADR, `accepted` et datée.
- **Aller chercher les documents externes tout seul (scan du dossier parent, workspace englobant)** — écarté : lecture hors périmètre non demandée. L'utilisateur désigne, le skill lit.

## Références

- Plan compagnon : [`../plans/2026-09-09-recolte-contexte-bootstrap.md`](../plans/2026-09-09-recolte-contexte-bootstrap.md)
- Skill modifié : `plugin/skills/bootstrap/SKILL.md` § *Phase 3 — Harvest the surrounding context*
- Filtre de référence réutilisé tel quel : `plugin/skills/capture-lessons/SKILL.md` § *Relevance criteria*
- Règle de numérotation des ADR respectée : `plugin/templates/fr/docs/workflow.md.tpl` § *Ne pas pré-attribuer un numéro d'ADR dans un item de backlog*
