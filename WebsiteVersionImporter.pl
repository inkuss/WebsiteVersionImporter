#!/usr/bin/perl -w

# Tasks:
# 3) Sichtbarmachen der Daten (Websites) in Edoweb3.
# Hierzu gibt es mehrere Möglichkeiten. Bevorzugt:
# 3.1) Auspacken der zip-Archive auf einem Server.
# 3.2) crawlen der ausgepackten Archive mit wget oder wpull und Konversion ins WARC-Format
# 3.3.1) Hinzufügen der gecrawlten Archive an bereits bestehende Objekte in Edoweb3. Dazu werden neue Objekte vom Typ "version" an bestehende Objekten vom Typ "website" angehängt. Dies betrifft 1577 Objekte vom Typ "version" die an 220 von den 347 Objekte vom Typ "website", die von Edo2 nach Edo3 importiert wurden (s. EDOZWO-430), angehängt werden müssen.
# 3.3.2) Neuanlage von Objekten vom Type "website" in Edoweb3 mit jeweils einer "version". Die Sites wurden nur einmalig gecrawlt und sollen auch in Zukunft nicht gecrawlt werden. Hierzu müssen neue Objekte vom Typ "website" angelegt werden, die in den Crawler Setting den Status "inaktiv" bekommen müssen. An die neuen Objekte wird jeweils eine "version" angehängt. Dies betrifft die 584 Sites, die in Edoweb1.0 (OPUS) angelegt und nach Edoweb2.0 migriert wurden (s. EDOZWO-431). 
use strict;
