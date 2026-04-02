import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";

const pb = new PocketBase(PB_URL);

async function backfill() {
    try {
        await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
        console.log("Connecté en admin. Lancement du double-audit...");

        const events = await pb.collection('events').getFullList();
        console.log(`${events.length} événements trouvés. Vérification...`);

        let conversationsCreated = 0;
        let ownersCreated = 0;

        for (const ev of events) {
            // 1. Vérification Conversation
            let hasConversation = false;
            try {
                await pb.collection('conversations').getFirstListItem(`event="${ev.id}"`);
                hasConversation = true;
            } catch (err) {
                if (err.status === 404) {
                    await pb.collection('conversations').create({ event: ev.id });
                    conversationsCreated++;
                    console.log(`[+] Conversation créée : ${ev.id}`);
                }
            }

            // 2. Vérification Membership (Owner)
            let hasOwnerMembership = false;
            try {
                await pb.collection('event_members').getFirstListItem(
                    `event="${ev.id}" && user="${ev.creator}" && role="owner" && status="accepted"`
                );
                hasOwnerMembership = true;
            } catch (err) {
                if (err.status === 404) {
                    await pb.collection('event_members').create({
                        event: ev.id,
                        user: ev.creator,
                        role: "owner",
                        status: "accepted"
                    });
                    ownersCreated++;
                    console.log(`[+] Propriétaire auto-relié en tant que membre : Event ${ev.id}, User ${ev.creator}`);
                }
            }
        }
        
        console.log(`\n✅ Terminé.`);
        console.log(`- Conversations manquantes restaurées : ${conversationsCreated}`);
        console.log(`- Propriétaires orphelins rattachés    : ${ownersCreated}`);
        
    } catch (e) {
        console.error("FATAL ERROR:", e);
    }
}

backfill();
