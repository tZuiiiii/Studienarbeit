# Nächste Schritte

1. Prototypische Oberfläche
2. Testen wie das mit dem Spiegel aussieht. 
3. Mit 3D Druck auseinandersetzten für Gehäuse
4. Recherche zu verschiedene Algos berteiben
5. Version der DHBW testen

# Geplantes Inhaltsverzeichnis
1. Einleitung
   
   Motivation und Problemstellung
   
   Zielsetzung und Forschungsfragen
   
2. Grundlagen
   
     2.1 Smart Mirrors & Ambient Intelligence
   
     - Definition, Anwendungsfelder, Stand der Technik

     2.2 Raspberry Pi / Embedded Systems
   
     - Architektur, Eignung für Bildverarbeitung
   
     2.3 Kontaktlose Pulsmessung (rPPG)
   
     - Funktionsprinzip
   
     - Algorithmen (ICA, POS, CHROM, Deep Learning Ansätze)
   
     - Einflussfaktoren (Bewegung, Licht, Hautfarbe)
     
     2.4 Emotionserkennung
   
     - Grundlagen der Gesichtsanalyse
   
     - Modelle (CNN, FER-Datasets, Pretrained Models)
   
     - Grenzen & ethische Aspekte (Bias, Datenschutz)
     
     2.5 Hardwarekomponenten
   
     - Industriekamera + Optik
   
     - Spiegelfolie / optische Eigenschaften
     
     2.6 3D Druck
   
     - Für Case
    
3. Durchführung
      3.1 Anforderungsanalyse
   
     - Genauigkeit von Puls- und Emotionserkennung
     
     3.2 Algorithmische Konzeption
   
     - Auswahl oder Training des Emotionserkennungsmodells
  

4. Implementierung
   
     4.1 Hardwareaufbau
   
     - Konstruktion des Spiegelgehäuses
   
     - Montage Spiegel/Display/Kamera
     
     4.2 Softwareimplementierung
   
       4.2.1 rPPG-Modul (Signalextraktion, Filter, Herzfrequenzberechnung)
   
       4.2.2 Emotionserkennungsmodell (Pipeline, Modellwahl, Inferenz)
   
       4.2.3 Backend-Logik
   
       4.2.4 Frontend
   
     4.3 Integration & Systemtests
  
5. Evaluation und Ergebnisse
   
     5.1 Testmethodik
   
     - Testaufbau, Versuchspersonen, Lichtbedingungen
     
     5.2 Messgenauigkeit rPPG

     - Vergleich mit Referenzgerät
   
     - Analyse der Fehlerquellen
     
     5.3 Leistung der Emotionserkennung
   
     - Accuracy, Confusion Matrix, typische Fehlklassifikationen
     
     5.4 Performance des Gesamtsystems
   
     - Latenz, CPU/GPU-Auslastung, Stabilität
     
     5.5 Diskussion
   
     - Interpretation
   
     - Vergleich mit Stand der Forschung
   
     - Grenzen
  
6. Zusammenfassung und Ausblick

