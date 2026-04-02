import PocketBase from 'pocketbase';
const pb = new PocketBase("http://127.0.0.1:8090");

async function fixRules() {
    // Auth admin
    await pb.admins.authWithPassword("thomas.spinner0@gmail.com", "Inscriptio&1");
    console.log("OK auth admin");

    // Récupérer la collection messages
    const col = await pb.collections.getOne("messages");
    console.log("Current createRule:", col.createRule);

    // Remplacer la createRule restrictive par une règle simple "juste être connecté"
    // La vérification membership accepted est déjà faite par le hook JS onRecordCreateRequest
    const updated = await pb.collections.update("messages", {
        createRule: '@request.auth.id != ""',
    });
    console.log("Updated createRule:", updated.createRule);
    console.log("DONE - messages createRule fixed. Hook JS reste la seule barrière métier.");
}

fixRules().catch(e => { console.error("FAILED:", e.message); });
