---
description: Vue tactique « qu'est-ce que je fais maintenant ? » — items restants classés par readiness (🔥 chaud · 🏗️ en cours · ✅ prêt · ⏳ sur déclencheur · 💤 fond de tiroir), tagués fix/feature + ADR.
---

# What's left

Produis une **vue tactique** de ce qu'il reste à faire : la réponse à *« qu'est-ce que je fais maintenant ? »*, pas un inventaire exhaustif. N'invente rien — agrège depuis les sources canoniques et **re-rends** sans les réécrire.

> **Axe primaire = readiness** (« puis-je agir dessus maintenant ? »), **pas** la priorité au repos du backlog. L'ordre au repos (ordre des sections du README) est la matière première ; tu le **ré-exprimes** en *est-ce actionnable*, et tu **compresses la longue traîne**.

## Sources canoniques (lire dans cet ordre)

1. **`docs/backlog/README.md`** — squelette. Ses sections sont la priorisation **au repos** ; elles alimentent le classement readiness (mapping plus bas), elles ne sont **pas** le plan de sections de la sortie.
2. **`docs/plans/<slug>.md`** avec frontmatter `status: in-progress` — extraire :
   - les `[ ]` non cochés de `## Prochaines actions` ;
   - les sujets ouverts de `## Questions ouvertes` non résolus (pas `~~…~~`) ;
   - les entrées `Lot N — …` de `## Lots d'implémentation` absentes de `## Progression` / du journal de décisions comme livrées.
   - **Détection de livraison silencieuse** : pour un Lot/Phase sans entrée « livré » dans `## Progression`/`## Journal de décisions`, vérifier côté code via un grep sur une chaîne distinctive. Code présent + plan silencieux ⇒ signaler en synthèse comme **livraison silencieuse à acter** — ne PAS lister comme TODO.

**À NE PAS utiliser** : `// TODO:` / `// FIXME:` du code (bruyant, non-canonique) ; les trackers d'issues sauf s'ils sont référencés depuis le backlog/un plan.

**À exclure** : les sections README de clôture/archive (ex. « Référence (sujets clos) »).

## Format de sortie

Une seule réponse. Entête, puis 5 sections **dans cet ordre fixe**, puis une synthèse.

**Entête** (1 ligne) :
```
# What's left — <date> · <N> items ouverts          🐛 fix · ✨ feature · 🛠️ tech · 🧭 doctrine
```

**Ligne d'item** (sections 🔥 / ✅) :
```
- <type> **Titre court** — pourquoi en 1 ligne · effort si connu · [ADR 00XX] · `backlog/<fichier>.md`
```
- `<type>` = un des 4 emojis (🐛 fix · ✨ feature · 🛠️ tech/dette/outillage · 🧭 doctrine/décision), inféré de la nature de l'item.
- `[ADR 00XX]` seulement si l'item référence une ADR/un plan. Sinon, omettre le tag.

**Ligne d'item** (section ⏳, le déclencheur est le titre) :
```
- ⏳ **<condition de déclenchement>** → <type> Titre de l'item · `backlog/<fichier>.md`
```

### Les 5 sections

1. **🔥 Chaud maintenant** *(promu par le contexte — 0 à 4 items max)*. Les items que la **session courante**, un **commit récent** ou une **release imminente** rendent pertinents *tout de suite*. Chacun **doit** porter le signal de contexte qui le promeut. Si aucun : écris *« Rien de promu par le contexte — vue au repos. »* et passe.
2. **🏗️ Chantiers en cours** *(par ADR / plan)*. Pour chaque plan `status: in-progress` : sous un titre `ADR 00XX — <sujet>`, les `[ ]` ouverts de `## Prochaines actions` + les Lots non livrés (avec leur tag type). Un plan sans rien d'ouvert : `ADR 00XX — <sujet> : rien d'ouvert`.
3. **✅ Prêt à démarrer** *(déclencheur satisfait ou aucun prérequis)*. **Sélectif** : priorité haute + actions ciblées + dette technique + bundles, dont rien ne bloque le démarrage. Trié par type. **Pas les N items** — seulement ceux réellement actionnables et dignes d'être proposés.
4. **⏳ Sur déclencheur** *(le déclencheur est le titre)*. Items en attente d'un signal : ceux avec un champ Trigger documenté **non encore satisfait**, plus les sections README type « en attente d'un signal » ou « doctrines à mûrir ». Scanne les conditions et **matche contre la réalité** ; un item dont le déclencheur paraît proche/atteint **remonte** en ✅ (dis-le en synthèse).
5. **💤 Fond de tiroir** *(compressé — jamais déroulé en mode normal)*. Le sommeil, les trous sans déclencheur : **comptés + pointeur**, pas listés. Ex. : `12 en sommeil sans déclencheur actif → backlog/README.md § Sommeil`.

**Synthèse (3-5 lignes)** : total d'items ouverts · **prochain pas naturel** (le 1ᵉʳ item de 🔥, sinon de 🏗️, sinon de ✅) · promotions/démotions de contexte avec leur pourquoi · signaux *stale* (item coché ailleurs mais pas au README, ou l'inverse ; livraison silencieuse) à nettoyer.
