---
status: accepted
date: 2026-07-02
deciders: [Plasma-AndraaX]
superseded-by:
related-adrs: []
related-plans: [2026-07-02-commande-coding-standards]
---

# ADR 0003 — Commande `/coding-standards` (proposer/actualiser les conventions via source vivante)

## Contexte

`docs/coding-standards.md` est **descriptif** : son titre dit « conventions *réellement en vigueur* », et la Phase 4 du bootstrap le remplit à partir du code **observé** (Phase 2). Sur un **projet neuf** (répertoire vide → Phase 2 skippée), il n'y a rien à observer et le fichier reste un squelette vide.

Besoin exprimé : pour un projet neuf, **proposer des conventions de départ selon la stack** choisie. Deux fausses pistes écartées d'emblée : (1) coupler ça au bootstrap (one-shot, alourdit une Phase 3 déjà longue, non rejouable) ; (2) figer une table « techno → conventions » dans le kit (elle rouille — le kit refuse déjà les listes baked-in pour la découverte plugins). Un test de faisabilité a confirmé que `find-docs`/`ctx7` remonte des conventions à jour et sourcées (formatter + style-guide) exploitables par synthèse.

## Décision

Ajouter une **commande dédiée `/coding-standards`**, générée dans **les deux profils** (car `coding-standards.md` ship en Minimal *et* Full), qui : lit la stack (argument, `CLAUDE.md`, ou détection) ; par langage, récupère les conventions idiomatiques via `find-docs`/`ctx7` **quand disponible** (sinon dégrade vers la connaissance du modèle, en le signalant) ; **synthétise** dans `docs/coding-standards.md` (pivot sur l'outillage + le nommage/structure que le formatter ne fixe pas), avec un statut explicite *« proposé, à confirmer »* ; **offre** (pas d'office) un `.editorconfig` de base. La commande reste **strictement documentaire** — elle n'installe ni ne configure aucun outil.

## Conséquences

- **Positives** — comble le trou du projet neuf sans alourdir le bootstrap ; réutilisable à tout moment (nouveau langage, actualisation) ; conventions **à jour et sourcées** via source vivante plutôt qu'une table morte ; honnête sur le statut « proposé » vs « en vigueur ».
- **Négatives** — dépend d'un outil externe (`find-docs`/`ctx7`) pour le meilleur résultat ; sans lui, la qualité retombe sur la connaissance du modèle (mitigé par un fallback explicite et signalé). Une commande de plus à maintenir en parité `en`/`fr`.
- **Neutres** — `/coding-standards` est dans les deux profils, contrairement à `/new-adr`/`/whats-left` (Full only) — cohérent avec le fait que `coding-standards.md` est un doc core des deux profils.

## Alternatives considérées

- **Intégrer au bootstrap (Phase 3/4)** — rejeté : couplage à un one-shot, non rejouable, alourdit la Phase 3.
- **Table figée « techno → conventions » dans le skill** — rejeté : se périme ; contraire au pattern « source vivante » déjà retenu pour les plugins.
- **Scaffolder les configs (`.prettierrc`, `.eslintrc`, installer les outils)** — rejeté : hors périmètre (« documentation/method scaffold, *not* an application scaffold »). Seul un `.editorconfig` (déclaratif, neutre, non exécutable) est *offert*, pas imposé.

## Références

- Plans liés : [`../plans/2026-07-02-commande-coding-standards.md`](../plans/2026-07-02-commande-coding-standards.md)
- Faisabilité : test `ctx7` sur `/prettier/prettier` (2026-07-02) — `library` + `docs` remontent des options de formatage à jour et sourcées.
