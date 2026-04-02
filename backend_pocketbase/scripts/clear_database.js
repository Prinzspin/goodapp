import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";

const pb = new PocketBase(PB_URL);

async function clear() {
    try {
        await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
        
        // Ordre strict pour éviter les erreurs de relation
        const collections = ["messages", "conversations", "event_likes", "event_members", "events", "users"];
        
        console.log("💣 Nettoyage complet dans l'ordre de dépendance...");

        for (const col of collections) {
            const records = await pb.collection(col).getFullList();
            console.log(`🧹 Suppression de ${records.length} records dans : ${col}`);
            for (const record of records) {
                await pb.collection(col).delete(record.id).catch(() => {});
            }
        }

        console.log("\n✨ LA BASE DE DONNÉES EST VIDE !");
    } catch (e) {
        console.error("❌ ERREUR:", e.message);
    }
}

clear();
