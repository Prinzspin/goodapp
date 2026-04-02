import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const GLOBAL_PASS = "azertyuiop";

async function debugChat() {
    const pb = new PocketBase(PB_URL);
    await pb.admins.authWithPassword("thomas.spinner0@gmail.com", "Inscriptio&1");
    
    try {
        const events = await pb.collection('events').getFullList();
        
        // Find an event with accepted members
        for (const ev of events) {
            const members = await pb.collection('event_members').getFullList({ filter: `event="${ev.id}" && status="accepted"` });
            if (members.length > 0) {
                // Find conversation
                let conv;
                try {
                    conv = await pb.collection('conversations').getFirstListItem(`event="${ev.id}"`);
                } catch(e) { continue; }
                
                const author = members[0].user;
                const authorUser = await pb.collection('users').getOne(author);
                
                pb.authStore.clear();
                await pb.collection('users').authWithPassword(authorUser.email, GLOBAL_PASS);
                
                try {
                    await pb.collection('messages').create({
                        conversation: conv.id,
                        author: author,
                        content: "Test message de bienvenue !"
                    });
                    console.log(`SUCCESS! Message envoyé par ${authorUser.email} sur event ${ev.id}`);
                    return;
                } catch(e) {
                    console.error("400 MESSAGE ERROR:", e.response.message, JSON.stringify(e.response.data));
                    return;
                }
            }
        }
        console.log("Aucun membre accepté trouvé pour le test.");
    } catch(e) {
        console.error("Fatal:", e);
    }
}

debugChat();
