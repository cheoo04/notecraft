# Cahier des charges
## Application de transformation de notes en documents structurés

*Version 2 — mise à jour après recherches sur les méthodes de prise de notes étudiantes et ajustements fonctionnels*

---

## 1. Contexte et présentation du projet

**Nom provisoire du projet** : *NoteToDoc* (à renommer)

**Porteur du projet** : Yah Mardochée KOUAKOU

**Contexte** : Les utilisateurs (étudiants en priorité, puis enseignants et professionnels) prennent souvent des notes brutes, désorganisées — texte, croquis, schémas — sur papier ou en numérique. La mise en forme de ces notes en un document présentable (rapport, résumé, exposé, support de cours) prend du temps et demande un effort de structuration important.

**Idée du projet** : Développer une application mobile (puis tablette), où l'utilisateur écrit, dessine et enregistre librement sur une "page blanche" numérique. Le contenu est ensuite analysé, compris et reformulé automatiquement par une intelligence artificielle pour produire, selon le besoin, un rapport, un résumé, un exposé, un support de cours, etc.

---

## 2. Objectifs du projet

### Objectif général
Automatiser la transformation de notes libres (texte, croquis, images, audio) en documents structurés et présentables.

### Objectifs spécifiques
- Permettre une saisie de notes rapide et naturelle (texte, esquisses/schémas, images, audio court)
- Analyser et comprendre le contenu saisi (idées principales, structure implicite, hiérarchie, schémas)
- Générer plusieurs types de documents à partir d'une même note, selon le format choisi
- Offrir un traitement à deux vitesses : rapide (express) ou approfondi (affiné)
- Permettre l'édition et l'ajustement du document généré
- Offrir un export dans des formats standards (PDF, Word, SVG pour les schémas)
- À terme, réduire la dépendance à des API tierces via un modèle entraîné en interne

---

## 3. Public cible

**Cible prioritaire (V1) : les étudiants.**

| Profil | Besoin principal |
|---|---|
| Étudiants (priorité V1) | Transformer des notes de cours (texte + schémas) en fiche de révision, résumé ou exposé |
| Enseignants (V2) | Structurer un plan de cours à partir d'idées brutes |
| Professionnels (V2) | Convertir des notes de réunion en compte-rendu ou rapport |

### Recherche sur les méthodes de prise de notes étudiantes

Pour concevoir une IA qui "comprend" vraiment des notes d'étudiant, il faut reconnaître les structures qu'ils utilisent réellement. Les méthodes les plus répandues :

- **Méthode Cornell** : page divisée en 3-4 zones — titre/référence en haut, notes détaillées à droite, mots-clés/questions à gauche, résumé en bas. Très répandue à l'université ; les étudiants relisent en cachant la colonne de droite pour se tester (principe proche des flashcards).
- **Mind mapping (carte mentale)** : un concept central, des branches et sous-branches. Utile pour les matières où les notions sont interconnectées plutôt que linéaires.
- **Sketchnoting** : mélange de dessins, icônes, flèches et texte. Très visuel, personnalisé, difficile à interpréter pour une IA classique car peu structuré — c'est justement ce que la fonction esquisse → SVG doit gérer.
- **Flow notes (méthode des flux)** : prise de notes libre avec flèches et liens entre idées, pour suivre un raisonnement qui va vite (cours dynamiques).
- **Outline method** : titre, sous-points indentés, sous-sous-points — la plus simple et minimaliste.
- **Étape commune à toutes les méthodes efficaces** : reformuler avec ses propres mots et transformer en fiches de révision dans les 24h suit un cours améliore nettement la rétention.

**Subtilités à intégrer dans l'IA d'analyse :**
- Détecter le type de structure utilisée (colonnes façon Cornell, flèches façon mind map/flow, indentation façon outline) pour adapter l'interprétation plutôt que d'appliquer un seul schéma de lecture.
- Reconnaître les schémas/croquis comme porteurs de sens (pas juste du texte) — un schéma fléché entre deux mots = une relation à restituer dans le document final.
- Permettre de générer, à partir d'une même note, un format "fiche de révision façon Cornell" (idéal pour réviser) en plus des formats rapport/résumé/exposé classiques.

---

## 4. Périmètre du projet

### Inclus dans le périmètre (V1 / MVP)
- Saisie de texte libre
- Saisie de croquis/schémas à main levée (esquisse), avec reconnaissance et reconstruction propre (export SVG ou image vectorielle nette)
- Ajout d'images aux notes (photo de tableau, de document, etc.)
- Ajout d'un enregistrement audio (30 minutes maximum) rattaché à une note, transcrit et intégré à l'analyse
- Choix du format de sortie parmi une liste prédéfinie (résumé, rapport, exposé, plan de cours, fiche de révision)
- Deux modes de génération : **Express** (rapide, réponse quasi immédiate) et **Affiné** (l'IA prend le temps d'analyser en profondeur, pour un résultat plus abouti — traitement différé, notification à la fin)
- Affichage et édition simple du résultat généré
- Export en PDF, et export SVG pour les schémas

### Hors périmètre (V1) — à envisager plus tard
- Travail collaboratif multi-utilisateurs
- Mode hors-ligne complet
- Extension tablette (prévue en V2, une fois le mobile validé)

---

## 5. Fonctionnalités détaillées

### 5.1 Fonctionnalités fonctionnelles

| # | Fonctionnalité | Description | Priorité |
|---|---|---|---|
| F1 | Zone de saisie libre | Page blanche numérique idéalement infinie (défilement vertical), navigable au zoom pour gagner en précision sur un schéma, avec bascule entre saisie texte structurée et saisie manuscrite au doigt/stylet | Haute |
| F2 | Esquisse → schéma propre | Dessiner à main levée un schéma, l'IA le reconstruit proprement (SVG ou image nette) | Haute |
| F3 | Ajout d'images | Insérer des photos dans une note (tableau, document, etc.) | Haute |
| F4 | Ajout d'audio (≤ 30 min) | Enregistrer un extrait audio rattaché à la note, transcrit automatiquement | Haute |
| F5 | Sélection du format de sortie | Menu : résumé / rapport / exposé / cours / fiche de révision | Haute |
| F6 | Mode Express vs Affiné | Choisir entre une génération rapide ou une analyse approfondie plus longue mais plus précise | Haute |
| F7 | Génération IA | Appel à un modèle de langage pour transformer la note selon le format et le mode choisis | Haute |
| F8 | Édition du résultat | Modifier le texte/schéma généré avant export | Haute |
| F9 | Export PDF / SVG | Télécharger le document final (texte en PDF, schémas en SVG) | Haute |
| F10 | Export Word | Télécharger en format modifiable | Moyenne |
| F11 | Historique des notes | Retrouver ses anciennes notes et documents générés | Moyenne |
| F12 | Choix du ton/style | Académique, professionnel, décontracté | Moyenne |
| F13 | Détection automatique du format suggéré | L'IA propose le format le plus adapté selon le contenu (ex. notes de cours → fiche de révision) | Moyenne |
| F14 | Génération de flashcards/quiz | À partir d'un cours, pour réviser | Basse (V2) |
| F15 | Bibliographie/citations automatiques | Mise en forme automatique des références présentes dans le texte | Basse (V2) |
| F16 | Multilingue | Générer le document dans une langue différente de la note d'origine | Basse (V2) |
| F17 | Mode collaboratif léger | Partager une note et son document généré | Basse (V2) |
| F18 | Extraction automatique de tâches | Détecter dans une note les actions concrètes et les proposer sous forme de liste structurée prête à planifier | Moyenne (V2) |
| F19 | Liaison entre notes similaires | Repérer automatiquement des notes au contenu proche (mots-clés, sujet) et les suggérer en lien entre elles | Basse (V2) |
| F20 | Priorisation automatique | Classer une note par urgence/importance perçue à la création (à affiner : l'IA suggère, l'utilisateur tranche — jamais l'inverse) | Basse (V2) |

### 5.2 Exigences non fonctionnelles

- **Ergonomie** : interface simple, fluide et dynamique, adaptée à l'usage tactile sur téléphone puis tablette
- **Performance perçue** : le mode Express doit rester rapide (quelques secondes) ; le mode Affiné peut prendre plus de temps mais l'utilisateur doit être informé de la progression
- **Disponibilité** : connexion internet requise pour l'appel à l'IA (V1)
- **Sécurité** : les notes, images et audios de l'utilisateur ne doivent pas être partagés sans son consentement
- **Portabilité** : mobile-first, extension tablette prévue ensuite

---

### 5.3 Décision technique : intégration des schémas dans le pipeline IA (F2)

Deux approches possibles pour qu'un schéma manuscrit soit pris en compte par
l'IA lors de la génération du document (et pas seulement exporté à part) :

| Approche | Coût | Ce qu'elle permet |
|---|---|---|
| A — Vectoriser puis décrire (OCR/vision) avant l'appel IA texte | Un appel modèle vision supplémentaire par schéma, en plus de la vectorisation SVG déjà prévue (F2) | Le schéma est restitué avec sens dans le document généré (relations, flèches) |
| B — Exclure du pipeline, traiter comme pièce jointe | Aucun appel supplémentaire | Rapide et fiable, mais le schéma n'est jamais intégré au texte généré — contredit l'objectif énoncé en section 3 ("un schéma fléché = une relation à restituer") |

**Approche recommandée (à valider) : hybride.** Extraire les métadonnées de
structure (formes, flèches, labels) directement pendant l'étape de
vectorisation SVG déjà prévue par F2, plutôt que de faire un second appel
vision dédié à la description. Cette structure légère (ex. `A → B`, `B → C`)
est ensuite injectée telle quelle dans le prompt texte. Coût marginal
proche de B, tout en satisfaisant l'exigence de la section 3. Reste à
valider une fois un premier pipeline de vectorisation en place — dépend de
la richesse des métadonnées que la méthode de vectorisation choisie
(`sketch-rnn` ou équivalent) peut effectivement extraire.

---

## 6. Choix technique

### Comparatif rapide (recherches 2026)

| Critère | Flutter (Impeller) | React Native (Fabric) |
|---|---|---|
| Fluidité / animations | 58-60 FPS constant sur interfaces complexes | ~51 FPS, léger retard sur l'animation lourde |
| Rendu | Moteur propre → rendu identique sur tous les appareils | Composants natifs → rendu qui peut varier selon l'OS |
| Démarrage à froid | Légèrement plus lent | ~200ms plus rapide |
| Batterie | — | ~12% de conso en moins |
| Multiplateforme (mobile + tablette + web) | Très bonne | Bonne, un peu moins unifiée |

**Décision : Flutter.** C'est le choix le plus cohérent avec l'objectif de rendu "fluide, dynamique et professionnel", et cela capitalise sur ton expérience déjà acquise sur ce framework (Nan-Nan Connect, Pharrell Phone).

### Stack proposée

| Composant | Technologie |
|---|---|
| Frontend | Flutter (mobile-first, puis tablette) |
| Dessin/esquisse | Canvas Flutter natif (CustomPainter) + reconstruction IA en SVG |
| Reconnaissance de schémas | Modèles de vectorisation de croquis (recherche : `sketch-rnn`, `Awesome-Sketch-Based-Applications` sur GitHub, qui référencent les approches de reconnaissance et vectorisation de dessins à main levée) |
| Audio | Enregistrement natif + transcription (Whisper ou équivalent) |
| Backend / orchestration | FastAPI (Python) ou Node.js |
| IA (V1) | API Claude (texte, structuration, génération) |
| Stockage | Firebase ou Supabase |
| Export documents | Génération PDF/Word/SVG côté backend |

---

## 7. Contraintes

- Coût des appels à l'API IA selon le volume d'utilisation
- Fiabilité variable de la reconnaissance d'écriture manuscrite et des schémas
- Nécessité d'une connexion internet pour la génération de documents (V1)
- Temps de traitement du mode Affiné à bien communiquer à l'utilisateur pour éviter la frustration
- Temps de développement disponible (projet étudiant, à planifier autour des cours)

---

## 8. Critères de validation du projet

Le projet sera considéré comme un succès si :
- L'utilisateur peut saisir une note libre (texte + schéma + éventuellement image/audio) et obtenir un document généré cohérent
- Au moins 3 formats de sortie sont disponibles et fonctionnels (résumé, rapport, fiche de révision)
- Les deux modes (Express / Affiné) sont opérationnels et donnent des résultats de qualité différente perceptible
- Un schéma dessiné à main levée peut être exporté proprement en SVG
- Le document généré est exportable en PDF

---

## 9. Planning prévisionnel (à affiner)

| Étape | Description |
|---|---|
| 1 | Validation du cahier des charges |
| 2 | Étude comparative des applications existantes (note-taking + IA) |
| 3 | Maquettage (wireframes) des écrans principaux |
| 4 | Développement du prototype (MVP) — texte + un format de sortie |
| 5 | Ajout progressif : esquisse/SVG, images, audio, mode Express/Affiné |
| 6 | Tests utilisateurs (étudiants) et ajustements |
| 7 | Version finale et déploiement mobile |
| 8 | Extension tablette |
| 9 | **Entraînement d'un modèle propre** (voir section 10) pour réduire la dépendance aux API externes |

---

## 10. Perspective à long terme : entraîner son propre modèle

Objectif : ne plus dépendre uniquement d'une API tierce (limites de débit, coûts si volume important, latence, ou alignement du modèle pas toujours adapté au besoin précis de l'appli).

**Pistes identifiées (recherches 2026) :**
- **Fine-tuning léger (LoRA / QLoRA)** sur un modèle open source (Llama 3/4, Mistral, Gemma) : on ne réentraîne pas tout le modèle, seulement une petite couche d'adaptation — accessible même sur une seule carte graphique grand public (ex. RTX 3090/4090) ou sur un Google Colab gratuit pour les petits modèles.
- **Hébergement local ou auto-hébergé** du modèle fine-tuné (via `llama.cpp` ou `Ollama`, formats GGUF) pour ne plus dépendre d'une API externe ni de ses limites de requêtes.
- **Combinaison RAG + fine-tuning** : garder une base de connaissances (méthodes de prise de notes, formats de documents) consultée par le modèle en plus du fine-tuning, pour un résultat plus précis et plus contrôlable.
- **Constitution d'un jeu de données propre** : conserver (avec accord des utilisateurs) des exemples de notes → documents générés et validés, pour créer un dataset d'entraînement spécifique à l'usage de l'appli.
- Le point de bascule (rentabilité) entre API payante et modèle auto-hébergé dépend du volume d'utilisation quotidien — à réévaluer une fois l'appli en usage réel.

Cette étape est prévue **après la V1 fonctionnelle**, une fois que l'usage réel (types de notes, formats demandés) aura permis de constituer des données d'entraînement pertinentes.

---

*Document à valider et amender avant de passer à l'étape suivante (étude de l'existant / maquettage).*
