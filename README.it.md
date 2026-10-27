# Kiratech — Cloud Native Support Engineer Junior Challenge

[English](README.md) | **Italiano**

WordPress e MySQL distribuiti su Kubernetes locale, con storage persistente, controlli di salute e troubleshooting documentato.

**Stato al 27 ottobre 2026:** progetto in corso, preparato per una revisione tecnica intermedia. La consegna finale non è ancora completa.

## Architettura

WordPress è un CMS open source esistente. Il suo container comprende Apache e PHP e comunica con MySQL tramite un Service interno.

- Due Deployment, ciascuno con una replica e strategia Recreate.
- Configurazione tramite ConfigMap e credenziali tramite Secret.
- Due PVC: dati MySQL in /var/lib/mysql e contenuti WordPress in /var/www/html/wp-content.
- Accesso tramite Service ClusterIP e port-forward locale.
- Startup, readiness e liveness probe.
- Richieste e limiti di CPU e memoria.

Il cluster ha un solo nodo. È un laboratorio senza alta disponibilità; la sostituzione dei Pod comporta una breve interruzione.

## Ambiente

Windows, Ubuntu su WSL2, Docker Desktop e Minikube.
Profilo: kiratech. Kubernetes: v1.36.1.

Configurazione verificata: [docs/local-setup.md](docs/local-setup.md).

## Attività verificate

- Installazione web di WordPress e accesso alla Dashboard.
- Installazione nuova senza riparazioni manuali del database.
- Persistenza di pubblicazione e immagine dopo la sostituzione separata dei Pod.
- Riproduzione e diagnosi del fallimento di inizializzazione MySQL.
- Correzione delle credenziali contenenti un newline finale.
- Aggiornamento del laboratorio: PHP 8.3.35 → 8.3.36, WordPress 7.1.2 → 7.1.3, Apache 2.4.68 → 2.4.69.
- Verifica della versione PHP sia da CLI sia dall'interfaccia web.
- Conservazione della pubblicazione e corrispondenza degli hash SHA-256 dei file caricati dopo l'aggiornamento.

## Documentazione

| Argomento | File |
| --- | --- |
| Ambiente locale | [docs/local-setup.md](docs/local-setup.md) |
| Manifest principale | [k8s/stack.yaml](k8s/stack.yaml) |
| Incidente MySQL | [docs/incidents/mysql-initialization.md](docs/incidents/mysql-initialization.md) |
| Installazione nuova | [docs/clean-install-test.md](docs/clean-install-test.md) |
| Persistenza | [docs/persistence-test.md](docs/persistence-test.md) |
| Aggiornamento di sicurezza | [labs/security/README.md](labs/security/README.md) |
| Evidenze | [docs/evidence/](docs/evidence/) |
| Diario di lavoro | [docs/work-log.md](docs/work-log.md) |
| Riferimenti upstream | [docs/sources.md](docs/sources.md) |

## Riprendere l'installazione esistente

Avviare Docker Desktop e verificare l'accesso a Docker da Ubuntu.
Dalla radice del repository:

    minikube start --profile kiratech
    kubectl --context=kiratech --namespace=wordpress get pods,pvc
    kubectl --context=kiratech --namespace=wordpress port-forward service/wordpress 8080:80

Aprire http://localhost:8080. Lasciare il port-forward attivo; Ctrl+C chiude il tunnel.

Per il laboratorio di sicurezza, in un terminale separato:

    kubectl --context=kiratech --namespace=wordpress-security port-forward service/wordpress 8082:80

Aprire http://localhost:8082. Il laboratorio attualmente usa l'immagine corretta.

Questi comandi riprendono installazioni esistenti. Le istruzioni complete per installazione da zero, verifica e rimozione sono ancora da consolidare.

## Credenziali e dati

Credenziali e backup sono conservati in .local/, esclusa da Git.
Modificare un Secret non modifica le password degli account MySQL già esistenti.

L'installazione principale conserva le credenziali originali dopo la riparazione manuale. La prova di installazione nuova e il laboratorio di sicurezza usano credenziali senza newline finale.

Lo storage è locale al nodo Minikube. Eliminare PVC o cluster può comportare perdita di dati.

## Limiti delle verifiche

- Nessun exploit eseguito e nessuna esecuzione remota di codice dimostrata.
- Ripristino dei backup e rollback non testati.
- Il log post-aggiornamento esaminato è un campione di 60 righe.
- L'aggiornamento non garantisce l'assenza di altre vulnerabilità.
- L'advisory PHP complementare del 23 ottobre resta un approfondimento pendente.
- Il progetto completo non è ancora stato verificato da un checkout Git pulito.

## Attività prima della consegna finale

- Secondo scenario operativo di troubleshooting e runbook finale.
- Istruzioni riproducibili di installazione, verifica e rimozione.
- Validazione da un checkout Git pulito.
- Diagramma dell'architettura.
- Proposta concettuale Krateo.
- Registro complessivo dell'utilizzo dell'IA e delle verifiche manuali.
- Condivisione del repository e prova della dimostrazione tecnica.

## Utilizzo dell'IA

L'IA ha supportato spiegazioni, analisi delle fonti, preparazione dei manifest, comandi diagnostici e documentazione. I comandi sono stati eseguiti manualmente e le conclusioni verificate usando output reali e advisory ufficiali.

Le attività non eseguite non sono presentate come testate. Il registro complessivo è ancora da consolidare; i documenti dell'incidente MySQL e del laboratorio di sicurezza descrivono già risultati e limiti specifici.

## Origine del software

- Packaging dell'immagine: https://github.com/docker-library/wordpress
- Esempio Kubernetes adattato: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Le modifiche riguardano configurazione, deployment, verifiche e procedure operative. Non è stata sviluppata una nuova applicazione WordPress.
