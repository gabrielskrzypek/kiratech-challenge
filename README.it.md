# Kiratech — Cloud Native Support Engineer Junior Challenge

[English](README.md) | **Italiano**

WordPress e MySQL distribuiti su Kubernetes locale, con storage persistente, controlli di salute, immagini personalizzate, un chart Helm e troubleshooting documentato.

**Stato al 30 ottobre 2026:** implementazione e documentazione dei laboratori completate e pubblicate, incluso Ingress. Le verifiche eseguite e i relativi limiti sono riportati nei documenti collegati; la preparazione della dimostrazione è separata.

## Architettura

WordPress è un CMS open source esistente. Il suo container comprende Apache e PHP e comunica con MySQL tramite un Service interno.

- Due Deployment, ciascuno con una replica e strategia Recreate.
- Configurazione tramite ConfigMap e credenziali tramite Secret.
- Due PVC: dati MySQL in /var/lib/mysql e contenuti WordPress in /var/www/html/wp-content.
- Accesso locale tramite port-forward diretto e laboratorio Ingress opzionale con Traefik.
- Startup, readiness e liveness probe.
- Richieste e limiti di CPU e memoria.

Il chart Helm deriva dal manifest Kubernetes funzionante. Usa nomi specifici della release e permette di configurare immagini, politiche di download, database, dimensioni dei volumi, risorse e nome del Secret esistente tramite i values. I file di override del laboratorio selezionano l'immagine iniziale o quella corretta.

Il cluster ha un solo nodo. È un laboratorio senza alta disponibilità; la sostituzione dei Pod comporta una breve interruzione.

## Ambiente

Windows, Ubuntu su WSL2, Docker Desktop e Minikube.
Profilo: kiratech. Kubernetes: v1.36.1. Helm: v4.3.1.

Configurazione verificata: [docs/local-setup.md](docs/local-setup.md).

## Percorso del progetto e risultati

| Fase | Attività e risultato | Approfondimento |
| --- | --- | --- |
| 1. Deployment iniziale e credenziali | WordPress/MySQL da manifest; diagnosi di HTTP 500 e autenticazione MySQL, riproduzione con newline nelle credenziali e verifica di una nuova installazione corretta | [Caso MySQL](docs/incidents/mysql-initialization.md) |
| 2. Persistenza | Sostituzione separata dei Pod WordPress e MySQL; articolo, immagine e volumi conservati | [Verifica](docs/persistence-test.md) |
| 3. Patch con immagine pubblicata | Diagnosi della versione PHP e sostituzione dell'immagine: PHP 8.3.35 → 8.3.36; anche WordPress passa da 7.1.2 a 7.1.3 | [Laboratorio sicurezza](labs/security/README.md) |
| 4. Patch con build propria e Helm | Analisi del Dockerfile, aggiornamento della base PHP/Apache e build; WordPress resta 7.1.3. Chart, template e values gestiscono installazione e upgrade, con contenuti e hash conservati | [Build e Helm](labs/security-build/README.md) |
| 5. Immagine non disponibile | Tag errato con policy Never: ErrImageNeverPull; diagnosi e recupero, inclusa la discordanza tra esito del rollback e risorse disponibili | [Incidente immagine](docs/incidents/image-not-available.md) |
| 6. Checkout pulito | Installazione, verifiche applicative e rimozione con nuove credenziali e PVC, riutilizzando cluster e immagini | [Rapporto](docs/fresh-checkout-test.md) |
| 7. Ingress e HTTP 503 | Traefik e accesso tramite hostname; selettore Service errato con Pod Ready, diagnosi degli endpoint e recupero senza riavvii | [Laboratorio Ingress](labs/ingress/README.md) |

I due percorsi di patch fanno parte del troubleshooting di sicurezza e sono
inclusi nel runbook, insieme ai casi MySQL, immagine assente e Ingress.

## Orientarsi nella documentazione

| Obiettivo | Punto di ingresso |
| --- | --- |
| Capire componenti e flussi | [Architettura e diagrammi](docs/architecture.md) |
| Installare il progetto | [Guida di installazione](docs/delivery-workflow.md) |
| Diagnosticare e correggere un problema | [Runbook L2: cinque casi](docs/runbook.md) |
| Riprodurre i laboratori e consultare le evidenze | [Mappa completa della documentazione](docs/README.md) |
| Valutare le proposte e il metodo | [Krateo](docs/krateo-proposal.md), [pipeline proposta](docs/delivery-workflow.md#proposed-cicd-workflow), [utilizzo dell'IA](docs/ai-usage.md) |

Il manifest iniziale è in [k8s/](k8s/stack.yaml); il packaging riutilizzabile
è in [charts/](charts/kiratech-wordpress/). I laboratori sono in labs/,
le procedure e i rapporti in docs/, gli output registrati in docs/evidence/.

## Installazione da zero

Iniziare dalla [guida di installazione e delivery](docs/delivery-workflow.md).
Il documento rimanda alla procedura completa del laboratorio e distingue
il flusso manuale eseguito dalla pipeline CI/CD proposta.

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

Per il laboratorio Helm con immagini personalizzate, in un terminale separato:

    helm list --kube-context kiratech -n wordpress-build
    kubectl --context=kiratech -n wordpress-build get deployments,pods,pvc
    kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80

Aprire http://localhost:8083; l'amministrazione è su http://localhost:8083/wp-admin/.
All'ultima verifica, questa release usava l'immagine personalizzata con PHP 8.3.36.

Questi comandi riprendono installazioni esistenti. La [guida del laboratorio personalizzato](labs/security-build/README.md) contiene istruzioni di build, installazione da zero, backup, aggiornamento, verifica e rimozione. Installazione e rimozione da un checkout pulito sono state verificate riutilizzando le immagini esistenti (vedi [rapporto](docs/fresh-checkout-test.md)); non ripetere l'inizializzazione delle credenziali su un database esistente.

## Laboratorio Ingress opzionale

La [guida del laboratorio Ingress](labs/ingress/README.md) descrive
l'installazione di Traefik, l'accesso tramite hostname e un ulteriore
incidente di instradamento.

- WordPress era Ready, ma un selettore errato del Service causava HTTP 503.
- L'ispezione degli EndpointSlice e l'accesso diretto isolavano il problema.
- Correggere il selettore ripristinava HTTP 200 senza riavviare i Pod.
- Uno script riutilizzabile verifica lo stato HTTP e il contenuto atteso.

## Credenziali e dati

Credenziali e backup sono conservati in .local/, esclusa da Git.
Modificare un Secret non modifica le password degli account MySQL già esistenti.

L'installazione principale conserva le credenziali originali dopo la riparazione manuale. La prova di installazione nuova ed entrambi i laboratori di sicurezza usano credenziali senza newline finale. Il laboratorio Helm usa file di credenziali dedicati e un Secret nel namespace wordpress-build. I values contengono il nome del Secret, non le password.

Lo storage è locale al nodo Minikube. Eliminare PVC o cluster può comportare perdita di dati.

## Limiti delle verifiche

- Nessun exploit eseguito e nessuna esecuzione remota di codice dimostrata.
- Ripristino dei backup non testato. Nel caso dell'immagine non disponibile, il rollback ha ripristinato le risorse Kubernetes ma Helm ha segnalato un errore; un successivo upgrade ha completato il recupero.
- Il log post-aggiornamento esaminato nel laboratorio con immagini pubblicate è un campione di 60 righe.
- L'aggiornamento non garantisce l'assenza di altre vulnerabilità.
- L'advisory PHP complementare del 23 ottobre resta un approfondimento pendente.
- Installazione e rimozione da checkout pulito verificate usando immagini e cluster esistenti. Non sono stati ripetuti la build delle immagini e tutti i laboratori.
- Le build personalizzate usano basi fissate tramite digest, ma i download esterni dei pacchetti impediscono di dichiarare una riproducibilità identica byte per byte.
- Il laboratorio personalizzato documenta una normalizzazione del formato LF eseguita dopo le prove di deployment.

## Preparazione della dimostrazione

- Provare il runbook L2 e gli scenari operativi documentati.
- Preparare la dimostrazione tecnica usando il repository pubblicato.

## Utilizzo dell'IA

L'IA ha supportato spiegazioni, analisi delle fonti, adattamento del Dockerfile, preparazione dei manifest e del chart Helm, comandi diagnostici e documentazione. I comandi sono stati eseguiti manualmente e le conclusioni verificate usando output reali e advisory ufficiali.

Il [registro dell'utilizzo dell'IA e delle verifiche manuali](docs/ai-usage.md) descrive il supporto ricevuto, i controlli effettuati e i limiti rimanenti. Le attività non eseguite non sono presentate come testate.

## Origine del software

- Packaging dell'immagine: https://github.com/docker-library/wordpress
- Esempio Kubernetes adattato: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Le modifiche riguardano configurazione, deployment, verifiche e procedure operative. Non è stata sviluppata una nuova applicazione WordPress.
