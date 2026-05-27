# Substances Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Combine supplement and medication tabs into one "Mittel" screen with a personal list, a substance database (local + API hybrid), and an automatic interaction checker.

**Architecture:** New `SubstancesScreen` with two internal `TabBar` tabs (`MySubstancesTab` + `DatabaseTab`). Existing Drift tables and data are untouched. A new `SubstanceCaches` Drift table stores API-fetched substances. `SubstanceRepository` searches bundled JSON first, then API, then caches. `InteractionService` checks all active user substances pairwise.

**Tech Stack:** Flutter, Drift ORM, Riverpod, GoRouter, `http` package (already in pubspec), `dart:convert`

---

## Task 1: Bundled substance asset

**Files:**
- Create: `assets/substances.json`
- Modify: `pubspec.yaml` (add asset path)

- [ ] **Step 1: Create `assets/substances.json`**

```json
[
  {
    "id": "ibuprofen",
    "name": "Ibuprofen",
    "type": "medication",
    "category": "Schmerzmittel / Entzündungshemmer",
    "atcCode": "M01AE01",
    "mechanism": "Hemmt COX-1 und COX-2, reduziert Prostaglandinsynthese.",
    "halfLife": "1.8–2.5 h",
    "commonDosage": "200–400 mg oral alle 6–8 h (max. 2400 mg/Tag)",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Magenbeschwerden", "frequencyPercent": 10.0},
      {"name": "Übelkeit", "frequencyPercent": 5.0},
      {"name": "Kopfschmerzen", "frequencyPercent": 3.0},
      {"name": "Schwindel", "frequencyPercent": 2.0}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "major", "description": "Erhöhtes Blutungsrisiko durch Hemmung der Thrombozytenaggregation und Verdrängung aus Proteinbindung."},
      {"withId": "aspirin", "withName": "Aspirin", "severity": "moderate", "description": "Gegenseitige Wirkungsabschwächung; erhöhtes GI-Blutungsrisiko."},
      {"withId": "sertralin", "withName": "Sertralin", "severity": "moderate", "description": "Erhöhtes Risiko für GI-Blutungen bei kombinierter Anwendung."},
      {"withId": "lisinopril", "withName": "Lisinopril", "severity": "moderate", "description": "NSAIDs können die blutdrucksenkende Wirkung von ACE-Hemmern abschwächen."}
    ]
  },
  {
    "id": "aspirin",
    "name": "Aspirin (ASS)",
    "type": "medication",
    "category": "Schmerzmittel / Thrombozytenaggregationshemmer",
    "atcCode": "B01AC06",
    "mechanism": "Irreversible Hemmung der COX-1 und COX-2; Hemmung der Thrombozytenaggregation.",
    "halfLife": "15–20 min (ASS); Salicylat 2–30 h",
    "commonDosage": "100 mg/Tag (kardioprotektiv); 500–1000 mg (Schmerz)",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "GI-Blutungen", "frequencyPercent": 2.5},
      {"name": "Magenschmerzen", "frequencyPercent": 8.0},
      {"name": "Tinnitus (bei hoher Dosis)", "frequencyPercent": 1.0}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "major", "description": "Stark erhöhtes Blutungsrisiko – Kombination nur unter strenger Überwachung."},
      {"withId": "ibuprofen", "withName": "Ibuprofen", "severity": "moderate", "description": "Ibuprofen kann die kardioprotektive Wirkung von niedrig-dosierter ASS aufheben."},
      {"withId": "omega3", "withName": "Omega-3 (Fischöl)", "severity": "moderate", "description": "Additive Hemmung der Thrombozytenaggregation; erhöhtes Blutungsrisiko."}
    ]
  },
  {
    "id": "paracetamol",
    "name": "Paracetamol",
    "type": "medication",
    "category": "Schmerzmittel / Antipyretika",
    "atcCode": "N02BE01",
    "mechanism": "Zentraler Mechanismus nicht vollständig geklärt; COX-3-Hemmung im ZNS.",
    "halfLife": "2–3 h",
    "commonDosage": "500–1000 mg oral alle 4–6 h (max. 4000 mg/Tag)",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Hepatotoxizität (Überdosis)", "frequencyPercent": null},
      {"name": "Hautausschlag", "frequencyPercent": 0.5}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "moderate", "description": "Regelmäßige Einnahme kann INR erhöhen – Monitoring empfohlen."},
      {"withId": "alkohol", "withName": "Alkohol", "severity": "major", "description": "Kombination erhöht das Risiko einer Leberschädigung erheblich."}
    ]
  },
  {
    "id": "warfarin",
    "name": "Warfarin",
    "type": "medication",
    "category": "Antikoagulanzien",
    "atcCode": "B01AA03",
    "mechanism": "Hemmt Vitamin-K-abhängige Gerinnungsfaktoren (II, VII, IX, X).",
    "halfLife": "36–42 h",
    "commonDosage": "Individuell (INR-gesteuert, typisch 2–10 mg/Tag)",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Blutungen", "frequencyPercent": 15.0},
      {"name": "Hautnekrose", "frequencyPercent": 0.1}
    ],
    "interactions": [
      {"withId": "vitamin_k2", "withName": "Vitamin K2", "severity": "major", "description": "Vitamin K antagonisiert direkt die Wirkung von Warfarin – INR kann stark fallen."},
      {"withId": "omega3", "withName": "Omega-3 (Fischöl)", "severity": "moderate", "description": "Kann die gerinnungshemmende Wirkung verstärken; INR-Kontrolle empfohlen."},
      {"withId": "johanniskraut", "withName": "Johanniskraut", "severity": "major", "description": "Johanniskraut induziert CYP2C9 und P-gp → stark reduzierte Warfarin-Wirkung."},
      {"withId": "ibuprofen", "withName": "Ibuprofen", "severity": "major", "description": "Erhöhtes Blutungsrisiko durch additive Wirkung und Proteinbindungsverdrängung."},
      {"withId": "aspirin", "withName": "Aspirin", "severity": "major", "description": "Stark erhöhtes Blutungsrisiko."},
      {"withId": "paracetamol", "withName": "Paracetamol", "severity": "moderate", "description": "Regelmäßige Einnahme kann INR erhöhen."}
    ]
  },
  {
    "id": "metformin",
    "name": "Metformin",
    "type": "medication",
    "category": "Antidiabetika",
    "atcCode": "A10BA02",
    "mechanism": "Hemmt hepatische Glukoneogenese; verbessert Insulinsensitivität.",
    "halfLife": "4–9 h",
    "commonDosage": "500–2000 mg/Tag in 2–3 Dosen",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Übelkeit / Durchfall", "frequencyPercent": 25.0},
      {"name": "Vitamin B12 Mangel (langfristig)", "frequencyPercent": 10.0}
    ],
    "interactions": [
      {"withId": "vitamin_b12", "withName": "Vitamin B12", "severity": "moderate", "description": "Metformin reduziert Vitamin-B12-Absorption; Supplementierung empfohlen bei Langzeittherapie."}
    ]
  },
  {
    "id": "sertralin",
    "name": "Sertralin",
    "type": "medication",
    "category": "Antidepressiva (SSRI)",
    "atcCode": "N06AB06",
    "mechanism": "Selektiver Serotonin-Wiederaufnahmehemmer (SSRI).",
    "halfLife": "26 h",
    "commonDosage": "50–200 mg/Tag",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Übelkeit", "frequencyPercent": 26.0},
      {"name": "Schlaflosigkeit", "frequencyPercent": 20.0},
      {"name": "Sexuelle Dysfunktion", "frequencyPercent": 15.0}
    ],
    "interactions": [
      {"withId": "johanniskraut", "withName": "Johanniskraut", "severity": "major", "description": "Risiko eines Serotonin-Syndroms; Kombination kontraindiziert."},
      {"withId": "ibuprofen", "withName": "Ibuprofen", "severity": "moderate", "description": "Erhöhtes GI-Blutungsrisiko durch additive Wirkung auf Thrombozytenfunktion."},
      {"withId": "melatonin", "withName": "Melatonin", "severity": "minor", "description": "SSRIs können Melatonin-Spiegel erhöhen; Kombination generell sicher, aber Schlaf beobachten."}
    ]
  },
  {
    "id": "lisinopril",
    "name": "Lisinopril",
    "type": "medication",
    "category": "ACE-Hemmer (Antihypertensiva)",
    "atcCode": "C09AA03",
    "mechanism": "Hemmt das Angiotensin-Converting-Enzyme (ACE).",
    "halfLife": "12 h",
    "commonDosage": "5–40 mg/Tag",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Trockener Husten", "frequencyPercent": 10.0},
      {"name": "Hyperkaliämie", "frequencyPercent": 3.0},
      {"name": "Schwindel", "frequencyPercent": 5.0}
    ],
    "interactions": [
      {"withId": "ibuprofen", "withName": "Ibuprofen", "severity": "moderate", "description": "NSAIDs können die blutdrucksenkende Wirkung abschwächen und Nierenfunktion beeinträchtigen."},
      {"withId": "kalium", "withName": "Kalium", "severity": "moderate", "description": "ACE-Hemmer erhöhen Kaliumspiegel; Kalium-Supplementierung kann zu Hyperkaliämie führen."}
    ]
  },
  {
    "id": "omeprazol",
    "name": "Omeprazol",
    "type": "medication",
    "category": "Protonenpumpenhemmer",
    "atcCode": "A02BC01",
    "mechanism": "Hemmt irreversibel die H+/K+-ATPase der Magenparietalzellen.",
    "halfLife": "0.5–1 h (Wirkdauer 24 h)",
    "commonDosage": "20–40 mg/Tag",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Kopfschmerzen", "frequencyPercent": 3.0},
      {"name": "Magnesiummangel (langfristig)", "frequencyPercent": 2.0},
      {"name": "Vitamin B12 Mangel (langfristig)", "frequencyPercent": 2.0}
    ],
    "interactions": [
      {"withId": "magnesium", "withName": "Magnesium", "severity": "minor", "description": "Langzeit-PPI-Therapie kann Magnesiumresorption reduzieren; Supplementierung ggf. sinnvoll."},
      {"withId": "vitamin_b12", "withName": "Vitamin B12", "severity": "minor", "description": "Reduzierte Vitamin-B12-Absorption bei Langzeittherapie."}
    ]
  },
  {
    "id": "metoprolol",
    "name": "Metoprolol",
    "type": "medication",
    "category": "Betablocker",
    "atcCode": "C07AB02",
    "mechanism": "Selektiver β1-Adrenozeptor-Antagonist.",
    "halfLife": "3–7 h",
    "commonDosage": "25–200 mg/Tag",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Müdigkeit", "frequencyPercent": 10.0},
      {"name": "Bradykardie", "frequencyPercent": 5.0},
      {"name": "Kälte der Extremitäten", "frequencyPercent": 5.0}
    ],
    "interactions": []
  },
  {
    "id": "levothyroxin",
    "name": "Levothyroxin",
    "type": "medication",
    "category": "Schilddrüsenhormone",
    "atcCode": "H03AA01",
    "mechanism": "Synthetisches T4-Schilddrüsenhormon.",
    "halfLife": "6–7 Tage",
    "commonDosage": "25–200 µg/Tag (nüchtern, 30 min vor dem Frühstück)",
    "evidenceGrade": null,
    "adverseEvents": [
      {"name": "Herzrasen (Überdosierung)", "frequencyPercent": null},
      {"name": "Schlaflosigkeit (Überdosierung)", "frequencyPercent": null}
    ],
    "interactions": [
      {"withId": "calcium", "withName": "Calcium", "severity": "moderate", "description": "Calcium reduziert Levothyroxin-Absorption; mind. 4h Abstand einhalten."},
      {"withId": "eisen", "withName": "Eisen", "severity": "moderate", "description": "Eisen reduziert Levothyroxin-Absorption; mind. 4h Abstand einhalten."}
    ]
  },
  {
    "id": "vitamin_d3",
    "name": "Vitamin D3",
    "type": "supplement",
    "category": "Vitamine",
    "atcCode": null,
    "mechanism": "Regulator des Calcium- und Phosphatstoffwechsels; immunmodulatorisch.",
    "halfLife": "14–21 Tage",
    "commonDosage": "1000–4000 IU/Tag (Erhaltung); bei Mangel bis 10.000 IU/Tag",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "Hyperkalzämie (hohe Dosen)", "frequencyPercent": null}
    ],
    "interactions": [
      {"withId": "calcium", "withName": "Calcium", "severity": "minor", "description": "Vitamin D3 steigert Calciumabsorption; bei hohen Dosen beider Substanzen auf Hyperkalzämie achten."}
    ]
  },
  {
    "id": "vitamin_c",
    "name": "Vitamin C",
    "type": "supplement",
    "category": "Vitamine",
    "atcCode": null,
    "mechanism": "Antioxidans; Cofaktor der Kollagensynthese; verbessert Eisenabsorption.",
    "halfLife": "30 min – 2 h",
    "commonDosage": "250–1000 mg/Tag",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Durchfall (hohe Dosen >2g)", "frequencyPercent": null},
      {"name": "Nierensteine (prädisponierte Personen)", "frequencyPercent": null}
    ],
    "interactions": [
      {"withId": "eisen", "withName": "Eisen", "severity": "minor", "description": "Vitamin C verbessert die Resorption von nicht-hämalem Eisen – vorteilhafte Interaktion."}
    ]
  },
  {
    "id": "magnesium",
    "name": "Magnesium",
    "type": "supplement",
    "category": "Mineralien",
    "atcCode": null,
    "mechanism": "Cofaktor für >300 Enzyme; wichtig für Muskel- und Nervenfunktion.",
    "halfLife": null,
    "commonDosage": "200–400 mg/Tag (elementares Magnesium)",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Durchfall (hohe Dosen)", "frequencyPercent": 10.0}
    ],
    "interactions": [
      {"withId": "calcium", "withName": "Calcium", "severity": "minor", "description": "Konkurrenz um Absorption; Einnahme zu verschiedenen Zeiten empfohlen bei hohen Dosen."}
    ]
  },
  {
    "id": "omega3",
    "name": "Omega-3 (Fischöl)",
    "type": "supplement",
    "category": "Fettsäuren",
    "atcCode": null,
    "mechanism": "EPA und DHA hemmen Thromboxan-A2-Synthese; entzündungshemmend.",
    "halfLife": null,
    "commonDosage": "1000–3000 mg EPA+DHA/Tag",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Fischiger Nachgeschmack", "frequencyPercent": 15.0},
      {"name": "GI-Beschwerden", "frequencyPercent": 5.0}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "moderate", "description": "Kann gerinnungshemmende Wirkung von Warfarin verstärken; INR-Monitoring empfohlen."},
      {"withId": "aspirin", "withName": "Aspirin", "severity": "moderate", "description": "Additive Hemmung der Thrombozytenaggregation; erhöhtes Blutungsrisiko bei hohen Dosen."}
    ]
  },
  {
    "id": "vitamin_b12",
    "name": "Vitamin B12",
    "type": "supplement",
    "category": "Vitamine",
    "atcCode": null,
    "mechanism": "Essenziell für Myelin-Synthese, DNA-Synthese und Erythropoese.",
    "halfLife": null,
    "commonDosage": "500–1000 µg/Tag (oral, bei Mangel)",
    "evidenceGrade": "A",
    "adverseEvents": [],
    "interactions": []
  },
  {
    "id": "zink",
    "name": "Zink",
    "type": "supplement",
    "category": "Mineralien",
    "atcCode": null,
    "mechanism": "Cofaktor für >200 Enzyme; wichtig für Immunfunktion und Wundheilung.",
    "halfLife": null,
    "commonDosage": "15–30 mg/Tag (elementares Zink)",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "Übelkeit (nüchtern)", "frequencyPercent": 10.0},
      {"name": "Kupfermangel (Langzeit, hohe Dosen)", "frequencyPercent": null}
    ],
    "interactions": [
      {"withId": "eisen", "withName": "Eisen", "severity": "moderate", "description": "Konkurrenz um intestinale Absorption; nicht gleichzeitig einnehmen."}
    ]
  },
  {
    "id": "melatonin",
    "name": "Melatonin",
    "type": "supplement",
    "category": "Hormone / Schlaf",
    "atcCode": null,
    "mechanism": "Endogenes Schlafhormon; reguliert den zirkadianen Rhythmus via MT1/MT2-Rezeptoren.",
    "halfLife": "0.5–1 h",
    "commonDosage": "0.5–5 mg, 30–60 min vor dem Schlafen",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "Schläfrigkeit (am nächsten Tag)", "frequencyPercent": 8.0},
      {"name": "Kopfschmerzen", "frequencyPercent": 3.0}
    ],
    "interactions": [
      {"withId": "sertralin", "withName": "Sertralin", "severity": "minor", "description": "SSRIs können endogene Melatoninspiegel erhöhen; Kombination meist sicher."}
    ]
  },
  {
    "id": "kreatin",
    "name": "Kreatin",
    "type": "supplement",
    "category": "Sport / Performance",
    "atcCode": null,
    "mechanism": "Erhöht intrazelluläre Phosphokreatin-Speicher; verbessert ATP-Regeneration.",
    "halfLife": null,
    "commonDosage": "3–5 g/Tag (Erhaltung); Loading: 20 g/Tag für 5–7 Tage",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Wassereinlagerung", "frequencyPercent": 20.0},
      {"name": "Magenunverträglichkeit (selten)", "frequencyPercent": 3.0}
    ],
    "interactions": []
  },
  {
    "id": "vitamin_k2",
    "name": "Vitamin K2 (MK-7)",
    "type": "supplement",
    "category": "Vitamine",
    "atcCode": null,
    "mechanism": "Cofaktor für Carboxylierung von Gerinnungsproteinen und Osteocalcin.",
    "halfLife": "72 h (MK-7)",
    "commonDosage": "90–200 µg/Tag",
    "evidenceGrade": "B",
    "adverseEvents": [],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "major", "description": "Vitamin K antagonisiert Warfarin direkt; kann INR stark senken und Thromboserisiko erhöhen."}
    ]
  },
  {
    "id": "johanniskraut",
    "name": "Johanniskraut",
    "type": "supplement",
    "category": "Pflanzenextrakte",
    "atcCode": null,
    "mechanism": "Hemmt Serotonin-, Dopamin- und Noradrenalin-Wiederaufnahme; starker CYP3A4/P-gp-Induktor.",
    "halfLife": "24–48 h (Hypericin)",
    "commonDosage": "300 mg 3× täglich (0.3% Hypericin-Extrakt)",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "Photosensitivität", "frequencyPercent": 3.0},
      {"name": "Schlaflosigkeit", "frequencyPercent": 2.0}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "major", "description": "Starker CYP2C9/P-gp-Induktor – Warfarin-Spiegel können stark fallen; Thromboserisiko."},
      {"withId": "sertralin", "withName": "Sertralin", "severity": "major", "description": "Risiko eines Serotonin-Syndroms (Agitation, Tremor, Tachykardie) – Kombination kontraindiziert."},
      {"withId": "paracetamol", "withName": "Paracetamol", "severity": "minor", "description": "Johanniskraut kann Paracetamol-Metabolismus leicht beschleunigen."}
    ]
  },
  {
    "id": "eisen",
    "name": "Eisen",
    "type": "supplement",
    "category": "Mineralien",
    "atcCode": null,
    "mechanism": "Zentrales Atom im Hämoglobin; essenziell für Sauerstofftransport und Elektronentransportkette.",
    "halfLife": null,
    "commonDosage": "50–200 mg elementares Eisen/Tag (bei Mangel)",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Verstopfung", "frequencyPercent": 20.0},
      {"name": "Übelkeit", "frequencyPercent": 15.0},
      {"name": "Schwarzer Stuhl", "frequencyPercent": 80.0}
    ],
    "interactions": [
      {"withId": "levothyroxin", "withName": "Levothyroxin", "severity": "moderate", "description": "Eisen reduziert Levothyroxin-Absorption; mind. 4h Abstand einhalten."},
      {"withId": "vitamin_c", "withName": "Vitamin C", "severity": "minor", "description": "Vitamin C verbessert die Eisenresorption – vorteilhafte Kombination."},
      {"withId": "zink", "withName": "Zink", "severity": "moderate", "description": "Konkurrieren um Absorption; nicht gleichzeitig einnehmen."}
    ]
  },
  {
    "id": "calcium",
    "name": "Calcium",
    "type": "supplement",
    "category": "Mineralien",
    "atcCode": null,
    "mechanism": "Strukturelles Mineral für Knochen; Second-Messenger in Zellsignalkaskaden.",
    "halfLife": null,
    "commonDosage": "500–1000 mg/Tag (elementares Calcium)",
    "evidenceGrade": "A",
    "adverseEvents": [
      {"name": "Verstopfung", "frequencyPercent": 10.0},
      {"name": "Aufgeblähtes Gefühl", "frequencyPercent": 5.0}
    ],
    "interactions": [
      {"withId": "levothyroxin", "withName": "Levothyroxin", "severity": "moderate", "description": "Calcium reduziert Levothyroxin-Absorption; mind. 4h Abstand."},
      {"withId": "eisen", "withName": "Eisen", "severity": "moderate", "description": "Calcium hemmt Eisenresorption; nicht gleichzeitig einnehmen."},
      {"withId": "vitamin_d3", "withName": "Vitamin D3", "severity": "minor", "description": "Vitamin D3 fördert Calciumabsorption – vorteilhafte Kombination, aber bei sehr hohen Dosen beider Hyperkalzämie-Risiko."}
    ]
  },
  {
    "id": "ashwagandha",
    "name": "Ashwagandha",
    "type": "supplement",
    "category": "Adaptogene",
    "atcCode": null,
    "mechanism": "Withanolide modulieren HPA-Achse; adaptogen, anxiolytisch.",
    "halfLife": null,
    "commonDosage": "300–600 mg/Tag (KSM-66 oder Sensoril-Extrakt)",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "GI-Beschwerden", "frequencyPercent": 5.0},
      {"name": "Schläfrigkeit", "frequencyPercent": 5.0}
    ],
    "interactions": [
      {"withId": "metoprolol", "withName": "Metoprolol", "severity": "minor", "description": "Ashwagandha kann blutdrucksenkende Wirkung leicht verstärken."}
    ]
  },
  {
    "id": "coq10",
    "name": "Coenzym Q10",
    "type": "supplement",
    "category": "Antioxidantien",
    "atcCode": null,
    "mechanism": "Cofaktor der Mitochondrialen Atmungskette; Antioxidans.",
    "halfLife": "33–35 h",
    "commonDosage": "100–300 mg/Tag",
    "evidenceGrade": "B",
    "adverseEvents": [
      {"name": "Übelkeit", "frequencyPercent": 3.0}
    ],
    "interactions": [
      {"withId": "warfarin", "withName": "Warfarin", "severity": "moderate", "description": "CoQ10 hat strukturelle Ähnlichkeit mit Vitamin K; kann INR beeinflussen."}
    ]
  },
  {
    "id": "folsaeure",
    "name": "Folsäure (Vitamin B9)",
    "type": "supplement",
    "category": "Vitamine",
    "atcCode": null,
    "mechanism": "Essenziell für DNA-Synthese und Ein-Kohlenstoff-Stoffwechsel; wichtig in der Schwangerschaft.",
    "halfLife": null,
    "commonDosage": "400 µg/Tag (Prophylaxe); 800–5000 µg (Schwangerschaft/Mangel)",
    "evidenceGrade": "A",
    "adverseEvents": [],
    "interactions": []
  }
]
```

- [ ] **Step 2: Add asset to `pubspec.yaml`**

In `pubspec.yaml`, find the `flutter:` → `assets:` section and add:
```yaml
    - assets/substances.json
```

- [ ] **Step 3: Commit**

```bash
git add assets/substances.json pubspec.yaml
git commit -m "feat: add bundled substances.json with 25 common substances and interactions"
```

---

## Task 2: Dart model classes

**Files:**
- Create: `lib/data/models/substance_info.dart`

- [ ] **Step 1: Create `lib/data/models/substance_info.dart`**

```dart
import 'dart:convert';

class AdverseEventInfo {
  final String name;
  final double? frequencyPercent;

  const AdverseEventInfo({required this.name, this.frequencyPercent});

  factory AdverseEventInfo.fromJson(Map<String, dynamic> j) =>
      AdverseEventInfo(
        name: j['name'] as String,
        frequencyPercent: (j['frequencyPercent'] as num?)?.toDouble(),
      );
}

class InteractionInfo {
  final String withId;
  final String withName;
  final String severity; // major | moderate | minor
  final String description;

  const InteractionInfo({
    required this.withId,
    required this.withName,
    required this.severity,
    required this.description,
  });

  factory InteractionInfo.fromJson(Map<String, dynamic> j) => InteractionInfo(
        withId: j['withId'] as String,
        withName: j['withName'] as String,
        severity: j['severity'] as String,
        description: j['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'withId': withId,
        'withName': withName,
        'severity': severity,
        'description': description,
      };
}

class SubstanceInfo {
  final String id;
  final String name;
  final String type; // 'medication' | 'supplement'
  final String? category;
  final String? atcCode;
  final String? mechanism;
  final String? halfLife;
  final String? commonDosage;
  final String? evidenceGrade;
  final List<AdverseEventInfo> adverseEvents;
  final List<InteractionInfo> interactions;
  final bool isLocal;

  const SubstanceInfo({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    this.atcCode,
    this.mechanism,
    this.halfLife,
    this.commonDosage,
    this.evidenceGrade,
    this.adverseEvents = const [],
    this.interactions = const [],
    this.isLocal = true,
  });

  factory SubstanceInfo.fromJson(Map<String, dynamic> j, {bool isLocal = true}) =>
      SubstanceInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        category: j['category'] as String?,
        atcCode: j['atcCode'] as String?,
        mechanism: j['mechanism'] as String?,
        halfLife: j['halfLife'] as String?,
        commonDosage: j['commonDosage'] as String?,
        evidenceGrade: j['evidenceGrade'] as String?,
        adverseEvents: ((j['adverseEvents'] as List?) ?? [])
            .map((e) => AdverseEventInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        interactions: ((j['interactions'] as List?) ?? [])
            .map((e) => InteractionInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLocal: isLocal,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        'atcCode': atcCode,
        'mechanism': mechanism,
        'halfLife': halfLife,
        'commonDosage': commonDosage,
        'evidenceGrade': evidenceGrade,
        'adverseEvents': adverseEvents.map((e) => {'name': e.name, 'frequencyPercent': e.frequencyPercent}).toList(),
        'interactions': interactions.map((e) => e.toJson()).toList(),
      };
}

class InteractionAlert {
  final String substanceAName;
  final String substanceBName;
  final String severity;
  final String description;

  const InteractionAlert({
    required this.substanceAName,
    required this.substanceBName,
    required this.severity,
    required this.description,
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/models/substance_info.dart
git commit -m "feat: add SubstanceInfo, InteractionInfo, AdverseEventInfo, InteractionAlert models"
```

---

## Task 3: Drift table for API cache + codegen

**Files:**
- Create: `lib/data/database/tables/substance_tables.dart`
- Modify: `lib/data/database/traum_database.dart`
- Modify: `lib/data/database/daos/substance_dao.dart` (new file)

- [ ] **Step 1: Create `lib/data/database/tables/substance_tables.dart`**

```dart
import 'package:drift/drift.dart';

class SubstanceCaches extends Table {
  TextColumn get substanceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get dataJson => text()();
  TextColumn get source => text()(); // 'openfda' | 'pubchem'
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {substanceId};
}
```

- [ ] **Step 2: Create `lib/data/database/daos/substance_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'substance_dao.g.dart';

@DriftAccessor(tables: [SubstanceCaches])
class SubstanceDao extends DatabaseAccessor<TraumDatabase>
    with _$SubstanceDaoMixin {
  SubstanceDao(super.db);

  Future<SubstanceCache?> findById(String id) =>
      (select(substanceCaches)..where((t) => t.substanceId.equals(id)))
          .getSingleOrNull();

  Future<List<SubstanceCache>> searchByName(String query) =>
      (select(substanceCaches)
            ..where((t) => t.name.lower().contains(query.toLowerCase())))
          .get();

  Future<void> upsert(SubstanceCachesCompanion entry) =>
      into(substanceCaches).insertOnConflictUpdate(entry);
}
```

- [ ] **Step 3: Register table + DAO in `lib/data/database/traum_database.dart`**

Add import at top:
```dart
import 'tables/substance_tables.dart';
import 'daos/substance_dao.dart';
```

Add to export list:
```dart
export 'tables/substance_tables.dart';
export 'daos/substance_dao.dart';
```

In the `@DriftDatabase(tables: [...])` annotation, add `SubstanceCaches` to the tables list.

Add DAO accessor to the `TraumDatabase` class body (alongside existing DAOs):
```dart
SubstanceDao get substanceDao => SubstanceDao(this);
```

- [ ] **Step 4: Run codegen**

```
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: generates `substance_dao.g.dart` with no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/data/database/tables/substance_tables.dart lib/data/database/daos/substance_dao.dart lib/data/database/daos/substance_dao.g.dart lib/data/database/traum_database.dart lib/data/database/traum_database.g.dart
git commit -m "feat: add SubstanceCaches Drift table and SubstanceDao"
```

---

## Task 4: SubstanceApiService

**Files:**
- Create: `lib/data/services/substance_api_service.dart`

- [ ] **Step 1: Create `lib/data/services/substance_api_service.dart`**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/substance_info.dart';

class SubstanceApiService {
  static const _fdaBase = 'https://api.fda.gov/drug/label.json';
  static const _pubchemBase =
      'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name';

  Future<SubstanceInfo?> fetchMedication(String query) async {
    try {
      final encoded = Uri.encodeComponent('"$query"');
      final uri = Uri.parse(
          '$_fdaBase?search=openfda.generic_name:$encoded+openfda.brand_name:$encoded&limit=1');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;
      final r = results.first;
      final openfda = r['openfda'] as Map<String, dynamic>? ?? {};
      final name = ((openfda['generic_name'] as List?)?.first as String?) ??
          ((openfda['brand_name'] as List?)?.first as String?) ??
          query;
      final mechanism = _firstString(r['mechanism_of_action']);
      final dosage = _firstString(r['dosage_and_administration']);
      final warningsRaw = _firstString(r['warnings']);
      final interactionsRaw = _firstString(r['drug_interactions']);

      return SubstanceInfo(
        id: 'fda_${query.toLowerCase().replaceAll(' ', '_')}',
        name: name,
        type: 'medication',
        category: 'Medikament',
        mechanism: mechanism?.length != null && mechanism!.length > 300
            ? '${mechanism.substring(0, 300)}…'
            : mechanism,
        commonDosage: dosage?.length != null && dosage!.length > 200
            ? '${dosage.substring(0, 200)}…'
            : dosage,
        adverseEvents: warningsRaw != null
            ? [AdverseEventInfo(name: warningsRaw.length > 200
                ? '${warningsRaw.substring(0, 200)}…'
                : warningsRaw)]
            : [],
        interactions: interactionsRaw != null
            ? [InteractionInfo(
                withId: 'unknown',
                withName: 'Verschiedene',
                severity: 'moderate',
                description: interactionsRaw.length > 300
                    ? '${interactionsRaw.substring(0, 300)}…'
                    : interactionsRaw,
              )]
            : [],
        isLocal: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SubstanceInfo?> fetchSupplement(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse('$_pubchemBase/$encoded/JSON');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final compounds =
          (data['PC_Compounds'] as List?)?.cast<Map<String, dynamic>>();
      if (compounds == null || compounds.isEmpty) return null;
      final props = (compounds.first['props'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      String? iupacName;
      for (final prop in props) {
        final urn = prop['urn'] as Map<String, dynamic>?;
        if (urn?['label'] == 'IUPAC Name' && urn?['name'] == 'Preferred') {
          iupacName = (prop['value'] as Map?)?.values.first as String?;
          break;
        }
      }
      return SubstanceInfo(
        id: 'pubchem_${query.toLowerCase().replaceAll(' ', '_')}',
        name: query,
        type: 'supplement',
        category: 'Supplement',
        mechanism: iupacName != null ? 'IUPAC: $iupacName' : null,
        isLocal: false,
      );
    } catch (_) {
      return null;
    }
  }

  String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first as String?;
    if (value is String) return value;
    return null;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/services/substance_api_service.dart
git commit -m "feat: add SubstanceApiService (OpenFDA + PubChem)"
```

---

## Task 5: SubstanceRepository (hybrid search)

**Files:**
- Create: `lib/data/repositories/substance_repository.dart`

- [ ] **Step 1: Create `lib/data/repositories/substance_repository.dart`**

```dart
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import '../database/traum_database.dart';
import '../models/substance_info.dart';
import '../services/substance_api_service.dart';

class SubstanceRepository {
  final SubstanceDao _dao;
  final SubstanceApiService _api;
  List<SubstanceInfo>? _local;

  SubstanceRepository(this._dao, this._api);

  Future<List<SubstanceInfo>> _loadLocal() async {
    _local ??= await _parseAsset();
    return _local!;
  }

  Future<List<SubstanceInfo>> _parseAsset() async {
    final raw = await rootBundle.loadString('assets/substances.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((j) => SubstanceInfo.fromJson(j)).toList();
  }

  Future<SubstanceInfo?> findById(String id) async {
    final local = await _loadLocal();
    final fromLocal = local.where((s) => s.id == id).firstOrNull;
    if (fromLocal != null) return fromLocal;
    final cached = await _dao.findById(id);
    if (cached != null) {
      return SubstanceInfo.fromJson(
          jsonDecode(cached.dataJson) as Map<String, dynamic>,
          isLocal: false);
    }
    return null;
  }

  Future<List<SubstanceInfo>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final local = await _loadLocal();
    final localResults =
        local.where((s) => s.name.toLowerCase().contains(q)).toList();
    if (localResults.length >= 3) return localResults;

    final cached = await _dao.searchByName(q);
    final cachedInfos = cached
        .map((c) => SubstanceInfo.fromJson(
            jsonDecode(c.dataJson) as Map<String, dynamic>,
            isLocal: false))
        .toList();

    final combined = [...localResults, ...cachedInfos];
    if (combined.length >= 3) return combined;

    final apiResult = await _fetchAndCache(q);
    if (apiResult != null) {
      final alreadyPresent =
          combined.any((s) => s.name.toLowerCase() == apiResult.name.toLowerCase());
      if (!alreadyPresent) combined.add(apiResult);
    }
    return combined;
  }

  Future<SubstanceInfo?> _fetchAndCache(String query) async {
    SubstanceInfo? result;
    result = await _api.fetchMedication(query);
    result ??= await _api.fetchSupplement(query);
    if (result == null) return null;
    await _dao.upsert(SubstanceCachesCompanion(
      substanceId: Value(result.id),
      name: Value(result.name),
      type: Value(result.type),
      dataJson: Value(jsonEncode(result.toJson())),
      source: Value(result.isLocal ? 'local' : 'api'),
    ));
    return result;
  }

  Future<List<SubstanceInfo>> getAll() => _loadLocal();
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/repositories/substance_repository.dart
git commit -m "feat: add SubstanceRepository with local-first hybrid search and API caching"
```

---

## Task 6: InteractionService + Riverpod providers

**Files:**
- Create: `lib/core/services/interaction_service.dart`
- Modify: `lib/core/providers/database_provider.dart`

- [ ] **Step 1: Create `lib/core/services/interaction_service.dart`**

```dart
import '../../data/models/substance_info.dart';
import '../../data/repositories/substance_repository.dart';

class InteractionService {
  final SubstanceRepository _repo;

  InteractionService(this._repo);

  Future<List<InteractionAlert>> checkSubstances(
      List<String> activeSubstanceNames) async {
    if (activeSubstanceNames.length < 2) return [];

    final all = await _repo.getAll();
    final nameToInfo = {
      for (final s in all) s.name.toLowerCase(): s,
    };

    final resolved = activeSubstanceNames
        .map((n) => nameToInfo[n.toLowerCase()])
        .whereType<SubstanceInfo>()
        .toList();

    final alerts = <InteractionAlert>[];
    final seen = <String>{};

    for (var i = 0; i < resolved.length; i++) {
      for (var j = i + 1; j < resolved.length; j++) {
        final a = resolved[i];
        final b = resolved[j];
        final key = '${a.id}|${b.id}';
        if (seen.contains(key)) continue;
        seen.add(key);

        for (final ix in a.interactions) {
          if (ix.withId == b.id || ix.withName.toLowerCase() == b.name.toLowerCase()) {
            if (ix.severity == 'major' || ix.severity == 'moderate') {
              alerts.add(InteractionAlert(
                substanceAName: a.name,
                substanceBName: b.name,
                severity: ix.severity,
                description: ix.description,
              ));
            }
            break;
          }
        }
        for (final ix in b.interactions) {
          if (ix.withId == a.id || ix.withName.toLowerCase() == a.name.toLowerCase()) {
            final alreadyAdded = alerts.any((al) =>
                (al.substanceAName == b.name && al.substanceBName == a.name) ||
                (al.substanceAName == a.name && al.substanceBName == b.name));
            if (!alreadyAdded && (ix.severity == 'major' || ix.severity == 'moderate')) {
              alerts.add(InteractionAlert(
                substanceAName: b.name,
                substanceBName: a.name,
                severity: ix.severity,
                description: ix.description,
              ));
            }
            break;
          }
        }
      }
    }
    return alerts;
  }
}
```

- [ ] **Step 2: Add providers to `lib/core/providers/database_provider.dart`**

Add the following imports at the top of the file:
```dart
import '../../data/repositories/substance_repository.dart';
import '../../data/services/substance_api_service.dart';
import '../../core/services/interaction_service.dart';
```

Add the following providers at the end of the file:
```dart
// ─── Substance ────────────────────────────────────────────────────────────────
final substanceDaoProvider = Provider<SubstanceDao>((ref) =>
    ref.watch(databaseProvider).substanceDao);

final substanceApiServiceProvider = Provider<SubstanceApiService>((_) =>
    SubstanceApiService());

final substanceRepositoryProvider = Provider<SubstanceRepository>((ref) =>
    SubstanceRepository(
      ref.watch(substanceDaoProvider),
      ref.watch(substanceApiServiceProvider),
    ));

final substanceSearchProvider =
    FutureProvider.autoDispose.family<List<SubstanceInfo>, String>((ref, q) =>
        ref.watch(substanceRepositoryProvider).search(q));

final interactionServiceProvider = Provider<InteractionService>((ref) =>
    InteractionService(ref.watch(substanceRepositoryProvider)));

final interactionAlertsProvider =
    FutureProvider.autoDispose<List<InteractionAlert>>((ref) async {
  final supps = ref.watch(supplementsStreamProvider).valueOrNull ?? [];
  final meds = ref.watch(allMedicationsStreamProvider).valueOrNull ?? [];
  final activeNames = [
    ...supps.where((s) => s.isActive).map((s) => s.name),
    ...meds.where((m) => m.isActive).map((m) => m.name),
  ];
  return ref.read(interactionServiceProvider).checkSubstances(activeNames);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/interaction_service.dart lib/core/providers/database_provider.dart
git commit -m "feat: add InteractionService and Riverpod substance providers"
```

---

## Task 7: SubstanceDetailSheet

**Files:**
- Create: `lib/features/substances/substance_detail_sheet.dart`

- [ ] **Step 1: Create `lib/features/substances/substance_detail_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/components/components.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_info.dart';

void showSubstanceDetailSheet(
  BuildContext context,
  SubstanceInfo substance, {
  VoidCallback? onAddPressed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubstanceDetailSheet(
      substance: substance,
      onAddPressed: onAddPressed,
    ),
  );
}

class _SubstanceDetailSheet extends StatelessWidget {
  final SubstanceInfo substance;
  final VoidCallback? onAddPressed;

  const _SubstanceDetailSheet({required this.substance, this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: TraumColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: substance.type == 'medication'
                      ? TraumColors.roseRedDim
                      : TraumColors.indigoBlueDim,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  substance.type == 'medication'
                      ? Icons.medication_rounded
                      : Icons.science_rounded,
                  color: substance.type == 'medication'
                      ? TraumColors.roseRed
                      : TraumColors.indigoBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(substance.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  Row(children: [
                    _TypeBadge(type: substance.type),
                    if (substance.evidenceGrade != null) ...[
                      const SizedBox(width: 6),
                      _EvidenceBadge(grade: substance.evidenceGrade!),
                    ],
                    if (!substance.isLocal) ...[
                      const SizedBox(width: 6),
                      _SourceBadge(),
                    ],
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (substance.category != null)
              _InfoRow(label: 'Kategorie', value: substance.category!),
            if (substance.atcCode != null)
              _InfoRow(label: 'ATC-Code', value: substance.atcCode!),
            if (substance.halfLife != null)
              _InfoRow(label: 'Halbwertszeit', value: substance.halfLife!),
            if (substance.mechanism != null) ...[
              const SizedBox(height: 12),
              _Section(title: 'Wirkung / Mechanismus'),
              Text(substance.mechanism!,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      height: 1.5)),
            ],
            if (substance.commonDosage != null) ...[
              const SizedBox(height: 16),
              _Section(title: 'Dosierung'),
              Text(substance.commonDosage!,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      height: 1.5)),
            ],
            if (substance.adverseEvents.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(title: 'Häufige Nebenwirkungen'),
              ...substance.adverseEvents.take(8).map((ae) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: TraumColors.coralOrange,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ae.frequencyPercent != null
                              ? '${ae.name} (${ae.frequencyPercent!.toStringAsFixed(0)}%)'
                              : ae.name,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 13),
                        ),
                      ),
                    ]),
                  )),
            ],
            if (substance.interactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(title: 'Bekannte Interaktionen'),
              ...substance.interactions.map((ix) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _severityColor(ix.severity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TraumRadius.chip),
                      border: Border.all(
                          color: _severityColor(ix.severity).withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.warning_rounded,
                            size: 14, color: _severityColor(ix.severity)),
                        const SizedBox(width: 6),
                        Text(ix.withName,
                            style: TextStyle(
                                color: _severityColor(ix.severity),
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const Spacer(),
                        Text(ix.severity.toUpperCase(),
                            style: TextStyle(
                                color: _severityColor(ix.severity),
                                fontFamily: 'DMSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 4),
                      Text(ix.description,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              height: 1.4)),
                    ]),
                  )),
            ],
            const SizedBox(height: 20),
            if (onAddPressed != null)
              GradientButton(
                label: 'Zu meinen Mitteln hinzufügen',
                onPressed: onAddPressed,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'major': return TraumColors.roseRed;
      case 'moderate': return TraumColors.coralOrange;
      default: return TraumColors.onBackgroundMuted;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isMed = type == 'medication';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMed ? TraumColors.roseRedDim : TraumColors.indigoBlueDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isMed ? 'Medikament' : 'Supplement',
        style: TextStyle(
          color: isMed ? TraumColors.roseRed : TraumColors.indigoBlue,
          fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EvidenceBadge extends StatelessWidget {
  final String grade;
  const _EvidenceBadge({required this.grade});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: TraumColors.mintGreenDim,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Evidenz $grade',
            style: const TextStyle(
                color: TraumColors.mintGreen,
                fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('API',
            style: TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans', fontSize: 11)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans', fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontSize: 13)),
          ),
        ]),
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/substances/substance_detail_sheet.dart
git commit -m "feat: add SubstanceDetailSheet with mechanism, dosage, adverse events, interactions"
```

---

## Task 8: MySubstancesTab

**Files:**
- Create: `lib/features/substances/my_substances_tab.dart`

- [ ] **Step 1: Create `lib/features/substances/my_substances_tab.dart`**

```dart
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/models/substance_info.dart';
import '../../l10n/app_localizations.dart';
import 'substance_detail_sheet.dart';

class MySubstancesTab extends ConsumerWidget {
  const MySubstancesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppsAsync = ref.watch(supplementsStreamProvider);
    final medsAsync = ref.watch(allMedicationsStreamProvider);
    final alertsAsync = ref.watch(interactionAlertsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logsAsync = ref.watch(medicationLogsForDateProvider(today));

    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.coralOrange,
        onPressed: () => _showAddTypeSelector(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          alertsAsync.when(
            data: (alerts) => alerts.isEmpty
                ? const SizedBox.shrink()
                : _InteractionBanner(alerts: alerts),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          medsAsync.when(
            data: (meds) => logsAsync.when(
              data: (logs) => _TodayStatusCard(meds: meds, logs: logs),
              loading: () => const ShimmerLoader(width: double.infinity, height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          suppsAsync.when(
            data: (supps) => medsAsync.when(
              data: (meds) {
                if (supps.isEmpty && meds.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meds.isNotEmpty) ...[
                      SectionHeader(title: 'Medikamente'),
                      const SizedBox(height: 8),
                      ...meds.map((med) => _MedCard(
                            med: med,
                            onDelete: () => ref.read(medicationDaoProvider).deleteMedication(med.id),
                            onToggle: null,
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (supps.isNotEmpty) ...[
                      SectionHeader(title: 'Supplements'),
                      const SizedBox(height: 8),
                      ...supps.map((s) => _SuppCard(
                            supp: s,
                            onDelete: () => ref.read(supplementDaoProvider).deleteSupplement(s.id),
                            onToggle: (active) =>
                                ref.read(supplementDaoProvider).updateSupplement(
                                  SupplementsCompanion(
                                    id: Value(s.id),
                                    name: Value(s.name),
                                    isActive: Value(active),
                                  ),
                                ),
                          )),
                    ],
                  ],
                );
              },
              loading: () => const ShimmerLoader(width: double.infinity, height: 200),
              error: (e, _) => Text('$e'),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 200),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }

  void _showAddTypeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Was möchtest du hinzufügen?',
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _TypeButton(
                icon: Icons.medication_rounded,
                label: 'Medikament',
                color: TraumColors.roseRed,
                dimColor: TraumColors.roseRedDim,
                onTap: () {
                  Navigator.pop(context);
                  _showAddMedSheet(context, ref);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeButton(
                icon: Icons.science_rounded,
                label: 'Supplement',
                color: TraumColors.indigoBlue,
                dimColor: TraumColors.indigoBlueDim,
                onTap: () {
                  Navigator.pop(context);
                  _showAddSuppSheet(context, ref);
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAddMedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddMedSheet(
        onAdd: (companion) async {
          await ref.read(medicationDaoProvider).insertMedication(companion);
          final timesJson = companion.timings.value;
          if (timesJson != '[]') {
            try {
              final times = (jsonDecode(timesJson) as List).cast<String>();
              for (int i = 0; i < times.length; i++) {
                final parts = times[i].split(':');
                await NotificationService.scheduleDailyAt(
                  id: 100 + i,
                  title: companion.name.value,
                  body: AppLocalizations.of(ctx)!.timeForMedication(companion.name.value),
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                  channelId: 'medication',
                );
              }
            } catch (_) {}
          }
        },
      ),
    );
  }

  void _showAddSuppSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => _AddSuppSheet(
        onAdd: (c) => ref.read(supplementDaoProvider).insertSupplement(c),
      ),
    );
  }
}

class _InteractionBanner extends StatelessWidget {
  final List<InteractionAlert> alerts;
  const _InteractionBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final hasM = alerts.any((a) => a.severity == 'major');
    final color = hasM ? TraumColors.roseRed : TraumColors.coralOrange;
    return GestureDetector(
      onTap: () => _showAlerts(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.warning_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${alerts.length} Interaktion${alerts.length == 1 ? '' : 'en'} erkannt — Tippe für Details',
              style: TextStyle(color: color, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  void _showAlerts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Interaktionen',
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          ...alerts.map((a) {
            final color = a.severity == 'major' ? TraumColors.roseRed : TraumColors.coralOrange;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TraumRadius.chip),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.warning_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text('${a.substanceAName} + ${a.substanceBName}',
                      style: TextStyle(color: color, fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text(a.severity.toUpperCase(),
                      style: TextStyle(color: color, fontFamily: 'DMSans',
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Text(a.description,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans', fontSize: 12, height: 1.4)),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final List<Medication> meds;
  final List<MedicationLog> logs;
  const _TodayStatusCard({required this.meds, required this.logs});

  @override
  Widget build(BuildContext context) {
    final activeMeds = meds.where((m) => m.isActive).toList();
    if (activeMeds.isEmpty) return const SizedBox.shrink();
    return TraumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Heute',
            style: TextStyle(color: TraumColors.onBackground,
                fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...activeMeds.map((med) {
          final times = _parseTimes(med.timings);
          final takenCount = logs.where((l) => l.medicationId == med.id && l.taken).length;
          final takenList = List.generate(times.length, (i) => i < takenCount);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MedicationDotRow(name: med.name, times: times, taken: takenList),
          );
        }),
      ]),
    );
  }

  List<String> _parseTimes(String t) {
    try { return (jsonDecode(t) as List).cast<String>(); } catch (_) { return []; }
  }
}

class _SuppCard extends StatelessWidget {
  final Supplement supp;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _SuppCard({required this.supp, required this.onDelete, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('supp_${supp.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: supp.isActive
                ? TraumColors.indigoBlue.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: _icon(Icons.science_rounded, TraumColors.indigoBlueDim, TraumColors.indigoBlue),
          title: Text(supp.name,
              style: const TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${supp.dosageAmount ?? '?'} ${supp.dosageUnit ?? ''}'.trim(),
            style: const TextStyle(color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans', fontSize: 12),
          ),
          trailing: Switch(
            value: supp.isActive,
            activeThumbColor: TraumColors.indigoBlue,
            onChanged: onToggle,
          ),
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _MedCard({required this.med, required this.onDelete, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final times = _parseTimes(med.timings);
    return Dismissible(
      key: ValueKey('med_${med.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: med.isActive
                ? TraumColors.roseRed.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: _icon(Icons.medication_rounded, TraumColors.roseRedDim, TraumColors.roseRed),
          title: Text(med.name,
              style: const TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (med.dosage != null || med.form != null)
              Text('${med.dosage ?? ''} ${med.form != null ? '· ${med.form}' : ''}'.trim(),
                  style: const TextStyle(color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 12)),
            if (times.isNotEmpty)
              Text(times.join(', '),
                  style: const TextStyle(color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans', fontSize: 11)),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: med.isActive ? TraumColors.mintGreenDim : TraumColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              med.isActive ? 'Aktiv' : 'Inaktiv',
              style: TextStyle(
                color: med.isActive ? TraumColors.mintGreen : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _parseTimes(String t) {
    try { return (jsonDecode(t) as List).cast<String>(); } catch (_) { return []; }
  }
}

Widget _deleteBg() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: TraumColors.roseRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
    );

Widget _icon(IconData icon, Color bg, Color fg) => Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 20),
    );

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color dimColor;
  final VoidCallback onTap;
  const _TypeButton({required this.icon, required this.label,
      required this.color, required this.dimColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: dimColor,
            borderRadius: BorderRadius.circular(TraumRadius.card),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color,
                fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.medication_liquid_rounded, size: 64,
                color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Noch keine Mittel',
                style: TextStyle(color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tippe auf + um Supplements oder\nMedikamente hinzuzufügen.',
                style: TextStyle(color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans', fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ─── Add sheets (copied + adapted from existing screens) ───────────────────

class _AddSuppSheet extends StatefulWidget {
  final Future<void> Function(SupplementsCompanion) onAdd;
  const _AddSuppSheet({required this.onAdd});
  @override
  State<_AddSuppSheet> createState() => _AddSuppSheetState();
}

class _AddSuppSheetState extends State<_AddSuppSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Vitamine';
  String _unit = 'mg';
  bool _saving = false;

  static const _categories = [
    'Vitamine', 'Mineralien', 'Aminosäuren', 'Protein', 'Omega-3',
    'Adaptogene', 'Pre-Workout', 'Darmgesundheit', 'Kreatin', 'Sonstige'
  ];
  static const _units = ['mg', 'g', 'µg', 'IU', 'ml', 'Kapsel(n)', 'Tablette(n)', 'Messbecher'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Supplement hinzufügen',
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: 'z.B. Vitamin D3'),
          const SizedBox(height: 12),
          const Text('Kategorie', style: TextStyle(color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _category,
            dropdownColor: TraumColors.surfaceElevated,
            isExpanded: true,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            underline: Container(height: 1, color: TraumColors.surfaceVariant),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Menge', _amountCtrl, hint: '1000', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Einheit', style: TextStyle(color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: _unit,
                dropdownColor: TraumColors.surfaceElevated,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                underline: Container(height: 1, color: TraumColors.surfaceVariant),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ]),
          ]),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving ? 'Speichern…' : 'Speichern',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans', fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true, fillColor: TraumColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name ist erforderlich')));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(SupplementsCompanion.insert(
      name: _nameCtrl.text.trim(),
      category: Value(_category),
      dosageAmount: Value(_amountCtrl.text.trim().isEmpty ? null : _amountCtrl.text.trim()),
      dosageUnit: Value(_unit),
    ));
    if (mounted) Navigator.pop(context);
  }
}

class _AddMedSheet extends StatefulWidget {
  final Future<void> Function(MedicationsCompanion) onAdd;
  const _AddMedSheet({required this.onAdd});
  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _form = 'Tablette';
  final List<String> _times = ['08:00'];
  bool _saving = false;

  static const _forms = ['Tablette', 'Kapsel', 'Tropfen', 'Injektion', 'Salbe', 'Spray', 'Sonstige'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Medikament hinzufügen',
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: 'z.B. Ibuprofen 400mg'),
          const SizedBox(height: 12),
          _field('Dosierung', _dosageCtrl, hint: 'z.B. 400 mg'),
          const SizedBox(height: 12),
          const Text('Form', style: TextStyle(color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _forms.map((f) {
              final sel = f == _form;
              return GestureDetector(
                onTap: () => setState(() => _form = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? TraumColors.roseRedDim : TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                    border: Border.all(color: sel ? TraumColors.roseRed : Colors.transparent),
                  ),
                  child: Text(f, style: TextStyle(
                      color: sel ? TraumColors.roseRed : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Erinnerungszeiten',
                style: TextStyle(color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 16, color: TraumColors.coralOrange),
              label: const Text('Hinzufügen',
                  style: TextStyle(color: TraumColors.coralOrange,
                      fontFamily: 'DMSans', fontSize: 12)),
            ),
          ]),
          ..._times.asMap().entries.map((e) => Row(children: [
            GestureDetector(
              onTap: () => _editTime(e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.chip),
                  border: Border.all(color: TraumColors.roseRed.withValues(alpha: 0.3)),
                ),
                child: Text(e.value, style: const TextStyle(
                    color: TraumColors.roseRed, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600)),
              ),
            ),
            if (_times.length > 1)
              IconButton(
                icon: const Icon(Icons.close, size: 16,
                    color: TraumColors.onBackgroundSubtle),
                onPressed: () => setState(() => _times.removeAt(e.key)),
              ),
          ])),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving ? 'Speichern…' : 'Speichern',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans', fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans'),
            filled: true, fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ]);

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times.add(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}'));
    }
  }

  Future<void> _editTime(int index) async {
    final parts = _times[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name ist erforderlich')));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(MedicationsCompanion.insert(
      name: _nameCtrl.text.trim(),
      dosage: Value(_dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim()),
      form: Value(_form),
      timings: Value(jsonEncode(_times)),
    ));
    if (mounted) Navigator.pop(context);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/substances/my_substances_tab.dart
git commit -m "feat: add MySubstancesTab with interaction banner, today status, unified supplement+medication list"
```

---

## Task 9: DatabaseTab

**Files:**
- Create: `lib/features/substances/database_tab.dart`

- [ ] **Step 1: Create `lib/features/substances/database_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/models/substance_info.dart';
import 'my_substances_tab.dart' show _showAddTypeSelector;
import 'substance_detail_sheet.dart';

class DatabaseTab extends ConsumerStatefulWidget {
  const DatabaseTab({super.key});

  @override
  ConsumerState<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends ConsumerState<DatabaseTab> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: 'Substanz suchen…',
              hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans'),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TraumColors.onBackgroundSubtle),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: TraumColors.onBackgroundSubtle),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _ctrl.text == v) {
                  setState(() => _query = v.trim());
                }
              });
            },
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _CategoryGrid(onCategoryTap: (cat) {
                  _ctrl.text = cat;
                  setState(() => _query = cat);
                })
              : _SearchResults(query: _query),
        ),
      ]),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final void Function(String) onCategoryTap;
  const _CategoryGrid({required this.onCategoryTap});

  static const _cats = [
    ('Vitamine', Icons.brightness_5_rounded, TraumColors.mintGreen),
    ('Mineralien', Icons.grain_rounded, TraumColors.indigoBlue),
    ('Schmerzmittel', Icons.healing_rounded, TraumColors.roseRed),
    ('Antidiabetika', Icons.bloodtype_rounded, TraumColors.coralOrange),
    ('Omega-3', Icons.water_drop_rounded, TraumColors.indigoBlue),
    ('Adaptogene', Icons.eco_rounded, TraumColors.mintGreen),
    ('Antidepressiva', Icons.psychology_rounded, TraumColors.coralOrange),
    ('Herz-Kreislauf', Icons.favorite_rounded, TraumColors.roseRed),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: _cats.map((c) => GestureDetector(
          onTap: () => onCategoryTap(c.$1),
          child: Container(
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
              border: Border.all(color: c.$3.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              Icon(c.$2, color: c.$3, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(c.$1,
                    style: const TextStyle(color: TraumColors.onBackground,
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ]),
          ),
        )).toList(),
      );
}

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(substanceSearchProvider(query));
    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, size: 48,
                  color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Keine Ergebnisse für "$query"',
                  style: const TextStyle(color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 14)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          itemBuilder: (ctx, i) => _ResultCard(substance: results[i]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: const TextStyle(color: TraumColors.roseRed,
                  fontFamily: 'DMSans'))),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final SubstanceInfo substance;
  const _ResultCard({required this.substance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMed = substance.type == 'medication';
    final color = isMed ? TraumColors.roseRed : TraumColors.indigoBlue;
    final dimColor = isMed ? TraumColors.roseRedDim : TraumColors.indigoBlueDim;

    return GestureDetector(
      onTap: () => showSubstanceDetailSheet(context, substance),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: dimColor, shape: BoxShape.circle),
            child: Icon(
              isMed ? Icons.medication_rounded : Icons.science_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(substance.name,
                  style: const TextStyle(color: TraumColors.onBackground,
                      fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              Row(children: [
                if (substance.category != null) ...[
                  Text(substance.category!,
                      style: const TextStyle(color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans', fontSize: 12)),
                  const SizedBox(width: 6),
                ],
                if (substance.evidenceGrade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.mintGreenDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Evidenz ${substance.evidenceGrade}',
                        style: const TextStyle(color: TraumColors.mintGreen,
                            fontFamily: 'DMSans', fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                if (!substance.isLocal) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Online',
                        style: TextStyle(color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans', fontSize: 10)),
                  ),
                ],
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: TraumColors.onBackgroundSubtle, size: 18),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/substances/database_tab.dart
git commit -m "feat: add DatabaseTab with category grid and live substance search"
```

---

## Task 10: SubstancesScreen (container)

**Files:**
- Create: `lib/features/substances/substances_screen.dart`

- [ ] **Step 1: Create `lib/features/substances/substances_screen.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'my_substances_tab.dart';
import 'database_tab.dart';

class SubstancesScreen extends StatelessWidget {
  const SubstancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TraumColors.background,
        appBar: AppBar(
          backgroundColor: TraumColors.background,
          title: const Text('Mittel',
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
          elevation: 0,
          bottom: TabBar(
            labelColor: TraumColors.coralOrange,
            unselectedLabelColor: TraumColors.onBackgroundMuted,
            indicatorColor: TraumColors.coralOrange,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontFamily: 'DMSans'),
            tabs: const [
              Tab(text: 'Meine Mittel'),
              Tab(text: 'Datenbank'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MySubstancesTab(),
            DatabaseTab(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/substances/substances_screen.dart
git commit -m "feat: add SubstancesScreen container with TabBar (Meine Mittel / Datenbank)"
```

---

## Task 11: Navigation update

**Files:**
- Modify: `lib/core/navigation/routes.dart`
- Modify: `lib/core/navigation/router.dart`

- [ ] **Step 1: Update `lib/core/navigation/routes.dart`**

Add the new route constant after the existing constants:
```dart
static const String substances = '/substances';
```

Replace the `moduleRoutes` map — remove `'supplements'` and `'medication'` entries, add `'substances'`:
```dart
static const Map<String, String> moduleRoutes = {
  'home': home,
  'training': training,
  'health': health,
  'nutrition': nutrition,
  'substances': substances,
  'planning': planning,
  'abstinence': abstinence,
  'budget': budget,
  'period': period,
  'profile': profile,
  'settings': settings,
};
```

Add `'substances'` case to `labelFor()`, remove `'supplements'` and `'medication'`:
```dart
case 'substances':
  return 'Mittel';
```

- [ ] **Step 2: Update `lib/core/navigation/router.dart`**

Add import:
```dart
import '../../features/substances/substances_screen.dart';
```

Remove the two existing `GoRoute` entries for `Routes.supplements` and `Routes.medication`.

Add instead (inside the `ShellRoute` routes list, where `supplements` was):
```dart
GoRoute(
  path: Routes.substances,
  builder: (_, __) => const SubstancesScreen(),
),
GoRoute(
  path: Routes.supplements,
  redirect: (_, __) => Routes.substances,
),
GoRoute(
  path: Routes.medication,
  redirect: (_, __) => Routes.substances,
),
```

Remove old imports from router.dart:
```dart
// Remove these two lines:
import '../../features/supplements/supplement_screen.dart';
import '../../features/medication/medication_screen.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/navigation/routes.dart lib/core/navigation/router.dart
git commit -m "feat: replace supplements+medication routes with unified substances route"
```

---

## Task 12: Build verification + final commit

- [ ] **Step 1: Run Flutter analysis**

```
flutter analyze
```

Expected: no errors. Warnings about unused imports from old screens are OK — fix any actual errors.

- [ ] **Step 2: Run build_runner to ensure codegen is up to date**

```
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: exits with code 0, no errors.

- [ ] **Step 3: Build debug APK to verify compilation**

```
flutter build apk --debug
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Verify navigation entry appears correctly**

Open the running app (or check `traum_scaffold.dart` / nav code) to confirm that only one "Mittel" navigation item appears where "Supplements" and "Medikamente" used to be two separate items.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: unified Substances screen – Meine Mittel + Datenbank with interaction checker"
```
