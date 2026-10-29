# Kiratech — Cloud Native Support Engineer Junior Challenge

[English](README.md) | **Italiano**

WordPress e MySQL distribuiti su Kubernetes locale, con storage persistente, controlli di salute, immagini personalizzate, un chart Helm e troubleshooting documentato.

**Stato al 29 ottobre 2026:** laboratorio di patch delle immagini personalizzate e aggiornamento Helm implementati, verificati funzionalmente e documentati. La consegna finale del challenge è ancora in corso.

## Architettura

WordPress è un CMS open source esistente. Il suo container comprende Apache e PHP e comunica con MySQL tramite un Service interno.

- Due Deployment, ciascuno con una replica e strategia Recreate.
- Configurazione tramite ConfigMap e credenziali tramite Secret.
- Due PVC: dati MySQL in /var/lib/mysql e contenuti WordPress in /var/www/html/wp-content.
- Accesso tramite Service ClusterIP e port-forward locale.
- Startup, readiness e liveness probe.
- Richieste e limiti di CPU e memoria.

Il chart Helm deriva dal manifest Kubernetes funzionante. Usa nomi specifici della release e permette di configurare immagini, politiche di download, database, dimensioni dei volumi, risorse e nome del Secret esistente tramite i values. I file di override del laboratorio selezionano l'immagine iniziale o quella corretta.

Il cluster ha un solo nodo. È un laboratorio senza alta disponibilità; la sostituzione dei Pod comporta una breve interruzione.

## Ambiente

Windows, Ubuntu su WSL2, Docker Desktop e Minikube.
Profilo: kiratech. Kubernetes: v1.36.1. Helm: v4.3.1.

Configurazione verificata: [docs/local-setup.md](docs/local-setup.md).

## Attività verificate

- Installazione web di WordPress e accesso alla Dashboard.
- Installazione nuova senza riparazioni manuali del database.
- Persistenza di pubblicazione e immagine dopo la sostituzione separata dei Pod.
- Riproduzione e diagnosi del fallimento di inizializzazione MySQL.
- Correzione delle credenziali contenenti un newline finale.
- Laboratorio con immagini pubblicate: PHP 8.3.35 → 8.3.36, WordPress 7.1.2 → 7.1.3, Apache 2.4.68 → 2.4.69.
- Laboratorio con immagini personalizzate: costruite due immagini WordPress 7.1.3 usando basi PHP/Apache fissate tramite versione e digest; PHP 8.3.35 → 8.3.36.
- Validazione del chart Helm e confronto dei manifest generati: tra le configurazioni cambia soltanto l'immagine WordPress.
- Installazione e aggiornamento Helm: patch-lab è passata dalla revisione 1 alla revisione 2 nel namespace wordpress-build.
- Aggiornamento personalizzato: PHP 8.3.36 verificato da CLI e web; MySQL e PVC conservati; articolo e immagine mantenuti con hash degli upload corrispondenti.
- Verifica della versione PHP sia da CLI sia dall'interfaccia web.
- Conservazione della pubblicazione e corrispondenza degli hash SHA-256 dei file caricati dopo l'aggiornamento.

## Documentazione

| Argomento | File |
| --- | --- |
| Ambiente locale | [docs/local-setup.md](docs/local-setup.md) |
| Manifest principale | [k8s/stack.yaml](k8s/stack.yaml) |
| Chart Helm | [charts/kiratech-wordpress/](charts/kiratech-wordpress/) |
| Incidente MySQL | [docs/incidents/mysql-initialization.md](docs/incidents/mysql-initialization.md) |
| Incidente immagine non disponibile | [docs/incidents/image-not-available.md](docs/incidents/image-not-available.md) |
| Runbook L2 | [docs/runbook.md](docs/runbook.md) |
| Architettura e diagramma | [docs/architecture.md](docs/architecture.md) |
| Installazione nuova | [docs/clean-install-test.md](docs/clean-install-test.md) |
| Persistenza | [docs/persistence-test.md](docs/persistence-test.md) |
| Aggiornamento con immagini pubblicate | [labs/security/README.md](labs/security/README.md) |
| Build personalizzata e aggiornamento Helm | [labs/security-build/README.md](labs/security-build/README.md) |
| Evidenze del laboratorio personalizzato | [docs/evidence/security-build/](docs/evidence/security-build/) |
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

Per il laboratorio Helm con immagini personalizzate, in un terminale separato:

    helm list --kube-context kiratech -n wordpress-build
    kubectl --context=kiratech -n wordpress-build get deployments,pods,pvc
    kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80

Aprire http://localhost:8083; l'amministrazione è su http://localhost:8083/wp-admin/.
All'ultima verifica, questa release usava l'immagine personalizzata con PHP 8.3.36.

Questi comandi riprendono installazioni esistenti. La [guida del laboratorio personalizzato](labs/security-build/README.md) contiene istruzioni di build, installazione da zero, backup, aggiornamento, verifica e rimozione. Resta da verificare la procedura completa da un checkout pulito; non ripetere l'inizializzazione delle credenziali su un database esistente.

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
- Il progetto completo non è ancora stato verificato da un checkout Git pulito.
- Le build personalizzate usano basi fissate tramite digest, ma i download esterni dei pacchetti impediscono di dichiarare una riproducibilità identica byte per byte.
- Il laboratorio personalizzato documenta una normalizzazione del formato LF eseguita dopo le prove di deployment.

## Attività prima della consegna finale

- Revisione finale e prova del runbook L2 con i due scenari operativi documentati.
- Consolidare le istruzioni generali di installazione, verifica e rimozione; la procedura del laboratorio personalizzato è già documentata.
- Validazione da un checkout Git pulito.
- Proposta concettuale Krateo.
- Registro complessivo dell'utilizzo dell'IA e delle verifiche manuali.
- Condivisione del repository e prova della dimostrazione tecnica.

## Utilizzo dell'IA

L'IA ha supportato spiegazioni, analisi delle fonti, adattamento del Dockerfile, preparazione dei manifest e del chart Helm, comandi diagnostici e documentazione. I comandi sono stati eseguiti manualmente e le conclusioni verificate usando output reali e advisory ufficiali.

Le attività non eseguite non sono presentate come testate. Il registro complessivo è ancora da consolidare; i documenti dell'incidente MySQL e del laboratorio di sicurezza descrivono già risultati e limiti specifici.

## Origine del software

- Packaging dell'immagine: https://github.com/docker-library/wordpress
- Esempio Kubernetes adattato: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Le modifiche riguardano configurazione, deployment, verifiche e procedure operative. Non è stata sviluppata una nuova applicazione WordPress.
