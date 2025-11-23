# Guida all'uso di Caffesaver

Benvenuto in **Caffesaver**, la versione potenziata di Bash Screensavers pensata per Mac (e Linux).

## 📥 Installazione

Segui questi semplici passaggi per installare l'applicazione:

### 1. Scarica il programma
Se non l'hai già fatto, scarica la cartella del progetto (o clona la repository) e apri il terminale al suo interno:

```bash
git clone https://github.com/attogram/bash-screensavers.git
cd bash-screensavers
```

### 2. Installa il comando
Esegui lo script di installazione per creare il comando globale `caffesaver`. Potrebbe esserti chiesta la password di amministratore (sudo) per copiare il collegamento nella cartella di sistema.

```bash
chmod +x install.sh
sudo ./install.sh
```

Se tutto è andato a buon fine, vedrai il messaggio: `Success! You can now run 'caffesaver' from anywhere.`

---

## 🎮 Come si usa

### Menu Principale
Per esplorare tutti gli screensaver disponibili, digita semplicemente:

```bash
caffesaver
```

### Avvio Rapido
Puoi lanciare uno screensaver specifico senza passare dal menu. Ad esempio, per avviare **Matrix**:

```bash
caffesaver -m matrix
```

### Opzione "No Sleep"
Su Mac, `caffesaver` impedisce automaticamente lo spegnimento dello schermo. Puoi anche usare l'opzione esplicita `-d`:

```bash
caffesaver -d -m pipes
```

### Uscita
*   Premi **Ctrl-C** in qualsiasi momento per chiudere l'applicazione e tornare al terminale.
*   Grazie alla nuova gestione del buffer, il tuo terminale rimarrà pulito e ordinato dopo l'uscita.

Buon divertimento!
