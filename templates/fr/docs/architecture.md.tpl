# Architecture

Comment {{PROJECT_NAME}} fonctionne *aujourd'hui*. C'est un **document vivant** — à mettre à jour au fil de l'évolution du système, pas comme un journal historique (pour l'historique, utiliser `git log`<!-- FULL-ONLY --> ou `docs/adr/`<!-- /FULL-ONLY -->).

> Garder ce document centré sur *ce qui existe*, pas sur *pourquoi ça a été choisi ainsi*. Pour le « pourquoi », renvoyer vers<!-- FULL-ONLY --> l'ADR concernée dans `docs/adr/` ou<!-- /FULL-ONLY --> une entrée datée de `docs/lessons-*.md`.

## Vue d'ensemble

<!-- Un paragraphe : que fait ce système, qui l'utilise, quelles sont les pièces mobiles principales. -->

## Composants majeurs

<!-- Une sous-section par module/service/couche majeur. Rester concis — renvoyer vers le code plutôt que le dupliquer. -->

### Composant A

### Composant B

## Modèle de données

<!-- Entités clés et leurs relations, si pertinent. Un schéma (même en ASCII) vaut mieux qu'un mur de texte. -->

## Flux clés

<!-- Les 2-4 flux les plus importants pour comprendre le système (ex. cycle de vie d'une requête, job de fond principal, flux d'auth). -->

## Préoccupations transverses

<!-- Auth, permissions, logging/observabilité, conventions de gestion d'erreur — tout ce qui traverse plusieurs composants. -->
