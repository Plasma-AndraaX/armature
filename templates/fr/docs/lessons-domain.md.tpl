# Leçons de domaine

**Règles métier** non-évidentes et invariants de domaine — le genre de chose qu'un développeur compétent se tromperait quand même sans qu'on le lui dise, parce que c'est une décision propre à ce projet, pas un fait général de programmation. Append-only — ajouter les nouvelles entrées en haut. Chaque entrée est datée.

> Ne générer/garder ce fichier que si le projet a un domaine non-trivial (règles métier qui ne sont pas évidentes rien qu'en lisant le code — logique de tarification, modèles de permissions, états de workflow, vocabulaire spécifique au domaine). Un outil/librairie/CLI purement technique n'en a généralement pas besoin — supprimer ce fichier dans ce cas plutôt que de le laisser vide.

## [Gabarit — copier cette forme pour une nouvelle entrée]

**[Titre actionnable énonçant la règle — ex. « Un Widget n'est jamais supprimé, seulement archivé »]**

[Corps : la règle, le raisonnement derrière si non-évident, et un pointeur vers l'endroit du code où elle est appliquée si pertinent.]

_Capturé le YYYY-MM-DD._

---

<!-- Les vraies entrées vont au-dessus de cette ligne, les plus récentes en premier. Supprimer l'entrée gabarit une fois du vrai contenu en place. -->
