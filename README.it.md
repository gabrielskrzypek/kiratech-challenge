# Kiratech — Cloud Native Support Engineer Junior Challenge

[English](README.md) | **Italiano**

WordPress e MySQL su Kubernetes locale: deployment, persistenza, correzione
di problemi di sicurezza e troubleshooting operativo, con evidenze registrate.

## Perché WordPress

Ho scelto WordPress perché il livello web, il database separato e i file
caricati permettono di verificare configurazione, problemi delle dipendenze
e persistenza. La scelta è stata motivata anche da un problema di sicurezza
segnalato recentemente nel runtime PHP di un'immagine WordPress, seguendo
il suggerimento del senior.

Il lavoro sulla sicurezza comprende due percorsi: sostituire l'immagine
pubblicata e analizzare il Dockerfile per ricostruirla con una base PHP/Apache
corretta. WordPress è l'applicazione esistente; docker-library/wordpress
fornisce il packaging dell'immagine adattato nel progetto. Non è stato
sviluppato un nuovo CMS.

## Architettura e ambiente

WordPress usa Apache/PHP e comunica con MySQL tramite un Service interno.
Il manifest Kubernetes iniziale è stato poi adattato in un chart Helm con
nomi specifici della release e configurazione tramite values.

- Due Deployment con una replica e strategia Recreate, probe di salute e richieste/limiti di risorse.
- Configurazione in un ConfigMap; credenziali del database referenziate da un Secret creato separatamente.
- PVC distinti per dati MySQL e contenuti WordPress, inclusi gli upload.
- Accesso locale tramite port-forward; instradamento per hostname opzionale con Traefik Ingress.

Ambiente testato: Ubuntu 26.04 su WSL2, Docker Desktop, Minikube 1.39.0,
Kubernetes 1.36.1 e Helm 4.3.1. Profilo/contesto del cluster: `kiratech`.
Vedi [architettura e diagrammi](docs/architecture.md) e [setup locale](docs/local-setup.md).

## Attività svolte e risultati

| Fase | Risultato | Documento |
| --- | --- | --- |
| Deployment iniziale | Diagnosi di HTTP 500 ed errore MySQL 1045; riproduzione del fallimento di inizializzazione con credenziali contenenti newline finale e verifica di una nuova installazione corretta | [Incidente MySQL](docs/incidents/mysql-initialization.md) |
| Persistenza | Articolo e immagine caricata conservati dopo la sostituzione separata dei Pod WordPress e MySQL | [Test di persistenza](docs/persistence-test.md) |
| Correzione con immagine pubblicata | Sostituzione dell'immagine interessata: PHP 8.3.35 → 8.3.36; anche WordPress passa da 7.1.2 a 7.1.3 | [Incidente di sicurezza](docs/incidents/php-security-image-update.md) |
| Build propria e Helm | Modifica della base PHP/Apache fissata nel Dockerfile, build e upgrade tramite values Helm; WordPress resta 7.1.3 e gli hash degli upload coincidono | [Incidente build e Helm](docs/incidents/php-security-custom-build.md) |
| Immagine non disponibile | Diagnosi di ErrImageNeverPull dovuto a un tag errato con policy Never; recupero del workload e riconciliazione dello stato Helm dopo un errore segnalato dal rollback | [Incidente immagine](docs/incidents/image-not-available.md) |
| Checkout pulito | Installazione, verifiche applicative e rimozione di un'istanza separata con nuove credenziali/PVC e cluster/immagini esistenti | [Test da checkout](docs/fresh-checkout-test.md) |
| Instradamento Ingress | Diagnosi di HTTP 503 con Pod Ready: un selettore Service non individuava backend. La correzione ha ripristinato l'accesso senza riavviare i Pod | [Incidente Ingress](docs/incidents/ingress-service-selector.md) |

I due casi di sicurezza affrontano lo stesso problema PHP analizzato con
percorsi di correzione diversi. Il runbook comprende tutti e cinque i casi
di troubleshooting.

## Utilizzare il progetto

L'installazione richiede Bash, Git, Python 3, Docker, kubectl, Minikube e Helm.
Avviare Docker Desktop prima di eseguire i comandi da WSL.

| Obiettivo | Istruzioni |
| --- | --- |
| Clonare, verificare gli strumenti e installare | [Punto di ingresso](docs/delivery-workflow.md); [laboratorio con immagini proprie](labs/security-build/README.md) per build/caricamento, credenziali, installazione e upgrade |
| Verificare o presentare | [Guida alla dimostrazione](docs/demo.md), inclusi accesso e controlli del runtime; la sequenza completa non è stata provata |
| Diagnosticare un problema | [Runbook L2](docs/runbook.md): MySQL, correzione con immagine pubblicata, build propria, immagine assente e Ingress |
| Configurare Ingress | [Laboratorio Traefik e instradamento](labs/ingress/README.md) |
| Rimuovere un'installazione | [Rimozione e perdita dei dati](labs/security-build/README.md#removal-and-data-loss); [rimozione verificata](docs/fresh-checkout-test.md#removal) |
| Consultare tutti i documenti | [Mappa della documentazione](docs/README.md) e [indice delle evidenze](docs/evidence/README.md) |

Struttura: [manifest iniziale](k8s/stack.yaml), [chart Helm](charts/kiratech-wordpress/),
[laboratori](labs/) e [documentazione](docs/README.md).

## Credenziali, dati e limiti

File di credenziali e backup restano in `.local/`, esclusa da Git.
I values contengono il nome del Secret, non le password. Modificare un Secret
non cambia le password di un database MySQL già inizializzato; vedi la
[procedura di aggiornamento della configurazione](docs/runbook.md#configuration-updates-and-running-pods).

- Laboratorio a nodo singolo con storage locale e interruzioni dovute a Recreate. Eliminare PVC o cluster può distruggere i dati.
- I controlli di sicurezza hanno valutato le versioni e verificato il comportamento applicativo; nessun exploit è stato eseguito e l'aggiornamento non dimostra l'assenza di altre vulnerabilità. L'advisory PHP complementare del 23 ottobre resta da valutare.
- Ripristino dei backup, alta disponibilità, TLS/Ingress pubblico e ricostruzione completa su una nuova macchina non testati. La validazione da checkout pulito ha riutilizzato immagini e cluster; non si dichiara una riproducibilità delle build identica byte per byte.
- [Integrazione Krateo](docs/krateo-proposal.md) e [CI/CD](docs/delivery-workflow.md#proposed-cicd-workflow) sono proposte, non integrazioni implementate.

I rapporti dettagliati conservano ambito, evidenze e limiti di ogni test.

## Supporto dell'IA e fonti

L'IA ha supportato spiegazioni, analisi, configurazione, comandi e documentazione.
I comandi sono stati eseguiti manualmente e i risultati verificati con output
reali, osservazioni nel browser e advisory ufficiali. Il [registro dell'utilizzo
dell'IA](docs/ai-usage.md) descrive assistenza, correzioni e limiti delle verifiche.

- Mirror del codice applicativo: https://github.com/WordPress/WordPress
- Packaging dell'immagine Docker: https://github.com/docker-library/wordpress
- Esempio di deployment adattato: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/
- [Riferimenti completi](docs/sources.md).
