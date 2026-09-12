# Supabase (classements + maps ODD)

1. Crée un projet sur [supabase.com](https://supabase.com).
2. Authentication → Providers → **Anonymous** : activé.
   Le message *« Anonymous users will use the authenticated role »* est normal :
   un joueur anonyme est juste un user connecté sans mot de passe. Les policies
   RLS du jeu sont faites pour ça.
3. SQL Editor (ou CLI) : applique dans l'ordre
   - `files...`
4. Project Settings → **API** :
   - **Project URL** : `https://xxxx.supabase.co` (sans `/rest/v1`)
   - **anon** `public` (JWT qui commence par `eyJ…`), pas `service_role`,
     et pas le nom `sb_publishable_…` comme nom de variable
5. Dans `.vscode/launch.json`, config **odd_game (supabase debug)**, colle ces
   deux valeurs dans `SUPABASE_URL` et `SUPABASE_ANON_KEY`, puis relance **Stop + F5**
   (un hot reload ne prend pas les `--dart-define`).

```
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Ne commite jamais la `service_role` key.

## Tables maps

`map_data` : toutes les maps (`id`, `name`, `created`, `data` = JSON complet,
`previewImg` = PNG en base64). Le bouton **Upload** du Map Maker (dialog
Generate, à côté de Copy) écrit ici et capture un screenshot de la preview.
Ça n'ajoute pas la map au menu tout seul. Si l'id existe déjà, une confirmation
demande d'écraser la map et de supprimer les temps (`best_times`) associés.

Page web `/admin` : grille de tuiles (preview + titre), cases campagne (15 max,
ordre = ordre de sélection) et DailyMap exclusive, suppression d'une map
(et de ses temps), plus purges (temps d'une map / tous les temps / tous les
users).

`content` : ce que l'app affiche :

| key | value |
|-----|--------|
| `maps` | tableau d'ids, dans l'ordre de la grille |
| `dailyMap` | id d'une map, ou `null` |

Exemple temporaire en SQL :

```sql
update public.content
set value = '["tutorial", "Rome"]'::jsonb
where key = 'maps';

update public.content
set value = '"Rome"'::jsonb
where key = 'dailyMap';
```

Tant que `maps` est `[]` (ou que Supabase est down), l'app utilise les JSON
bundle / le dernier cache.
