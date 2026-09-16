# Étude de l'existant — Applications concurrentes ou proches
### Projet : transformation de notes (texte, esquisse, image, audio) en documents structurés

---

## 1. Panorama des applications proches du concept (2026)

| Application | Ce qu'elle fait bien | Limites par rapport à notre projet |
|---|---|---|
| **GoodNotes 6** | Référence sur tablette pour l'écriture manuscrite ; fonctions IA récentes de résumé et d'aide à la révision ; grand choix de templates | Pensée tablette/iPad d'abord (pas mobile-first) ; ne génère pas plusieurs formats de documents (rapport, exposé...) à partir d'une note ; pas de gestion d'audio intégrée poussée |
| **Nebo (MyScript)** | Le meilleur du marché pour transformer une esquisse à main levée en schéma propre (formes et connecteurs nets) et en texte ; utilisé par des étudiants en technique pour des schémas de circuits, par exemple | Pas de génération de documents variés (rapport/exposé/cours) ; pas de gestion audio ; courbe d'apprentissage assez raide ; centré tablette |
| **Notion AI** | Très bon pour rédiger, résumer et structurer du texte ; écosystème de templates riche | Pas de reconnaissance de croquis/schémas à main levée ; l'IA avancée est réservée au forfait payant le plus cher ; pensé "espace de travail", pas "page blanche → document" |
| **Zoho Notebook** | Mélange texte, checklists, audio et croquis dans des cartes multimédias | Pas de génération de documents structurés par IA ; reste un outil de capture, pas de transformation |
| **Otter.ai** | Très bon sur la transcription audio en temps réel et les résumés de réunion | Centré audio uniquement, pas de texte libre ni de schémas ; orienté réunions professionnelles, pas étudiants |
| **NotebookLM** | Bon pour transformer des documents existants en notes sourcées et résumés | Part de documents déjà écrits, ne capture pas une note manuscrite/esquisse/audio à la base |
| **Apple Notes + Apple Intelligence** | Gratuit, résumé et mise en forme basique par IA | Fonctions IA limitées, pas de génération multi-format, pas de reconnaissance de schémas avancée |

---

## 2. Ce que fait chaque catégorie d'application (synthèse)

- **Les apps d'écriture manuscrite** (GoodNotes, Nebo, Notability) excellent pour *capturer* et parfois *nettoyer* l'écriture/les schémas, mais ne transforment pas la note en un document d'un autre type (rapport, exposé...).
- **Les apps "second cerveau" avec IA** (Notion AI, Obsidian, Mem, Tana) excellent pour *organiser et rédiger* du texte, mais ne prennent pas en charge le dessin/schéma ni l'audio comme source de note.
- **Les apps audio** (Otter, Fireflies, Granola) excellent sur la *transcription*, mais restent mono-format (résumé de réunion) et ignorent le texte manuscrit et les schémas.
- **Aucune application identifiée ne combine** : (a) saisie mobile-first, (b) texte + esquisse/schéma + image + audio dans une même note, (c) génération de plusieurs formats de documents différents à la demande, (d) un choix explicite entre traitement rapide et traitement approfondi.

---

## 3. Angle différenciant du projet

C'est précisément là que se situe l'opportunité :

1. **Mobile-first** : la quasi-totalité des apps avancées sur l'esquisse/l'écriture (GoodNotes, Nebo, Notability) sont pensées pour tablette + stylet. Une expérience fluide sur téléphone, sans stylet, est un axe de différenciation.
2. **Une seule note, plusieurs sources** : texte + croquis + image + audio (30 min) réunis dans une même entrée, contrairement aux apps qui se spécialisent sur une seule modalité.
3. **Une note → plusieurs documents** : personne ne propose de partir d'une note unique pour générer, au choix, un résumé, un rapport, un exposé, un cours ou une fiche de révision.
4. **Deux vitesses de traitement (Express / Affiné)** : concept absent des apps étudiées, qui proposent une génération instantanée unique, sans option d'analyse plus poussée.
5. **Ciblage étudiant assumé** avec les méthodes de prise de notes (Cornell, mind mapping, sketchnoting) prises en compte nativement dans l'analyse IA — les apps généralistes ne s'adaptent pas à ces structures spécifiques.

---

## 4. Points de vigilance à retenir de la concurrence

- Nebo montre que la reconnaissance de schémas à main levée est faisable et appréciée, mais demande un vrai travail technique (courbe d'apprentissage signalée comme un point faible chez eux — à éviter dans notre UX).
- Le modèle économique de Notion (IA avancée réservée au forfait le plus cher) est un point de friction cité par les utilisateurs — à anticiper dans le futur modèle de monétisation.
- Les apps de transcription audio se limitent souvent aux réunions ; un audio court et rattaché à une note de cours reste un terrain peu exploité.

---

*Prochaine étape suggérée : maquettage (wireframes) des écrans principaux en tenant compte de ces constats.*
