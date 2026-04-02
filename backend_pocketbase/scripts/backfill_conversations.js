import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";

const pb = new PocketBase(PB_URL);

async function backfill() {
    try {
        await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
        console.log("Connecté en admin.");

        const events = await pb.collection('events').getFullList();
        console.log(`${events.length} événements trouvés. Vérification des conversations manuellement...`);

        let createdCount = 0;
        for (const ev of events) {
            try {
                // Tentative de récupération d'une conversation déjà reliée
                await pb.collection('conversations').getFirstListItem(`event="${ev.id}"`);
            } catch (err) {
                if (err.status === 404) {
                    await pb.collection('conversations').create({ event: ev.id });
                    createdCount++;
                    console.log(`[RÉPARÉ] Conversation recréée pour l'événement > ${ev.title || ev.id}`);
                } else {
                    console.error(`Status inconnu sur l'événement ${ev.id}:`, err);
                }
            }
        }
        
        console.log(`\n✅ Terminé. ${createdCount} conversations manquantes ont été générées et soudées en base.`);
        console.log(`(Vous pouvez relancer ce script sans aucun danger)`);
    } catch (e) {
        console.error("FATAL ERROR:", e);
    }
}

backfill();
