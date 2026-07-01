# Préférences personnelles

Chaque contributeur a ici un fichier portant son login (identifiant de session local — `$USER`, ou `git config user.name` en repli) : `<login>.md`, committé dans le dépôt.

Claude charge automatiquement le fichier correspondant au login local au début de chaque session.

## Ce qui va dans ton fichier

- Préférences de communication (longueur des réponses, langue, niveau de verbosité).
- Préférences de workflow (stratégie de branches, format des messages de commit, souhait ou non de trailers co-auteur, etc.).
- Raccourcis personnels (chemins, alias, commandes spécifiques à ton environnement).

## Ce qui n'y va PAS

- Une convention que toute l'équipe doit suivre → `CLAUDE.md` ou un autre doc partagé.
- Une décision sur le projet → `docs/adr/` ou `docs/backlog/`.
- Une leçon technique → `docs/lessons-technical.md`.

## Créer ton fichier

Copier la forme ci-dessous dans `docs/prefs/<ton-login>.md` :

```markdown
# Prefs — <login>

## Communication
- Langue : <ex. français, anglais>
- Longueur des réponses : <ex. concise, détaillée>

## Workflow
- Branches : <ex. feature branches, trunk-based>
- Style de commit : <ex. Conventional Commits, pas de trailer co-auteur>

## Raccourcis
- <tout ce qui est spécifique à l'environnement de ta machine>
```
