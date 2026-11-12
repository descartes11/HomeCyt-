# MaCité — application Flutter

Gestion locative pour bailleurs et locataires (FCFA, Mobile Money), recréée en Flutter à partir des maquettes v2 et du design system **Broadsheet** (`../design_handoff_macite_v2`).

Cibles : Android, iOS, web, Windows. Material 3, police Montserrat, icônes Phosphor duotone.

## Lancer l'application

```bash
flutter pub get
flutter run -d chrome     # web : démarre sur la page d'accueil publique
flutter run -d <android>  # mobile : démarre sur l'écran de démarrage
flutter test              # tests (tous les écrans × 5 tailles × clair/sombre)
```

### Comptes de démonstration

Les données sont fictives et restent en mémoire. Comme dans la maquette, **le premier essai de connexion affiche le bandeau « Pas de connexion internet »** : appuyez sur « Réessayer ».

| Espace | Identifiant | Mot de passe |
| --- | --- | --- |
| Locataire (Sarah M.) | `07 12 34 56 02` ou `sarah.m@mail.com` | n'importe lequel |
| Bailleur (Daniel A.) | tout autre numéro (8 chiffres) ou e-mail | n'importe lequel |

## Structure

```
lib/
  main.dart                 routes, thème clair/sombre, transitions
  app_state.dart            mode sombre global, noms des routes
  theme/
    app_theme.dart          tokens Broadsheet (couleurs, rayons, ombres, typo) + ThemeData
    palette.dart            couleurs sémantiques clair/sombre (Pal), tons des badges (Tone)
  widgets/
    ui.dart                 boutons, badges, puces, cartes, segmented, switch, emplacements photo…
    fields.dart             champs, listes déroulantes, cases à cocher
    shell.dart              barre de navigation mobile, barre latérale et en-tête « ordinateur »
    anim.dart               apparitions, transitions d'écran, squelettes, flottement
    icons.dart              icônes Phosphor duotone (généré, voir plus bas)
  features/
    landing/                page d'accueil publique (web)
    auth/                   démarrage, accueil, présentation, connexion, inscription
    tenant/                 espace locataire (état + écrans + envoi de justificatif)
    landlord/               espace bailleur (état + écrans + revue de justificatif)
```

Chaque espace a un « store » (`ChangeNotifier`) qui reprend la logique des maquettes : validation des formulaires, statuts des loyers, justificatifs, signalements, annonces, filtres, notifications. Les écrans s'adaptent : sous 1024 px, mise en page mobile (barre de navigation en bas) ; au-delà, mise en page « ordinateur » (barre latérale, tableaux, kanban).

## Écarts assumés par rapport au handoff

- **Police** : Montserrat (à la place de Source Serif 4 du design system, à la demande du client), embarquée dans `assets/fonts/Montserrat-*.ttf` (licence SIL OFL 1.1) : rendu identique sur toutes les plateformes, hors ligne.
- **Icônes** : `phosphor_flutter` 2.1.0 ne compile plus avec Flutter 3.47 (`IconData` est devenue `final`). La police Phosphor Duotone (licence MIT) est embarquée et `lib/widgets/icons.dart` déclare les icônes utilisées. Pour en ajouter une, reprendre ses deux points de code (principal et secondaire) dans `phosphor_icons_duotone.dart` du paquet d'origine.
- **Photos** : emplacements vides hachurés, à remplacer par `ClipRRect` (rayon 2) + `BoxFit.cover`.
- **PDF** : quittances, fiches locataires et bail sont générés sur l’appareil (`lib/services/pdf_docs.dart`, paquets `pdf` + `printing`), puis proposés via le menu de partage (ouvrir, enregistrer, envoyer).
- **Appels, SMS** : simulés par un message de confirmation.
- **Comptes** : le profil choisi à l’inscription est mémorisé sur l’appareil (`lib/services/accounts.dart`, `shared_preferences`) pour ouvrir le bon espace à la connexion.

## Prochaines étapes

- Brancher une vraie API / base de données à la place des stores en mémoire.
- Prise de photo (`image_picker`) pour les justificatifs, la CNI et les signalements.
- Photo du reçu dans les quittances, signature du bailleur.
