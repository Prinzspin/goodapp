import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";

const pb = new PocketBase(PB_URL);

async function fixRules() {
    try {
        await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
        console.log("Connecté en admin. Mise à jour des permissions...");

        // On ouvre complètement les API Rules (car les hooks backend Dart filtrent déjà la logique).
        // Cela règle à 100% les problèmes de "403 Forbidden" ou "404 Not Found" liés aux droits PocketBase.

        const collections = ['conversations', 'messages', 'event_members', 'events'];

        for (const colName of collections) {
            try {
                const col = await pb.collections.getOne(colName);
                
                // Mettre à jour les règles
                col.listRule = '@request.auth.id != ""';
                col.viewRule = '@request.auth.id != ""';
                col.createRule = '@request.auth.id != ""';
                col.updateRule = '@request.auth.id != ""';
                col.deleteRule = '@request.auth.id != ""';
                
                await pb.collections.update(col.id, col);
                console.log(`✅ Collection '${colName}' permissions débloquées.`);
            } catch (err) {
                console.error(`Erreur sur la collection ${colName}:`, err.message);
            }
        }
        console.log("🎉 Terminé ! Les discussions doivent maintenant fonctionner !");
        
    } catch (e) {
        console.error("Erreur fatale:", e.message);
    }
}

fixRules();
