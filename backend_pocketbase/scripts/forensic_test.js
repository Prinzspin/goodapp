import PocketBase from 'pocketbase';
const pb = new PocketBase("http://127.0.0.1:8090");

async function run() {
    // Authentification en tant qu'USER (pas admin)
    const authData = await pb.collection("users").authWithPassword("test@goodapp.com", "azertyuiop");
    console.log("Auth user ID:", authData.record.id);
    console.log("AuthStore model ID:", pb.authStore.model?.id);
    
    // Vérifier les memberships du compte test
    const memberships = await pb.collection("event_members").getFullList({
        filter: `user = "${authData.record.id}" && status = "accepted"`
    });
    console.log("Accepted memberships:", memberships.length);
    if (memberships.length === 0) {
        console.log("PROBLEM: test@goodapp.com has NO accepted memberships! Cannot send messages.");
        return;
    }
    
    // Récupérer une conversation valide pour ce user
    const eventId = memberships[0].event;
    console.log("Using event:", eventId);
    
    const convs = await pb.collection("conversations").getFullList({ filter: `event = "${eventId}"` });
    if (convs.length === 0) {
        console.log("PROBLEM: No conversation for event:", eventId);
        return;
    }
    const conv = convs[0];
    console.log("Using conversation:", conv.id);
    
    // Envoi du message avec auth USER
    try {
        const res = await pb.collection("messages").create({
            conversation: conv.id,
            author: authData.record.id,
            content: "FORENSIC TEST " + Date.now()
        });
        console.log("SUCCESS! Message created:", res.id, "->", res.content);
    } catch (e) {
        console.error("FAILED:", e.message);
        if (e.response) console.error("Response:", JSON.stringify(e.response));
    }
    
    // Vérifier en base
    const msgs = await pb.collection("messages").getFullList({ sort: '-created', perPage: 3 });
    console.log("Total messages now:", msgs.length);
    for(const m of msgs) console.log(" ->", m.id, "|", m.content, "|", m.author);
}

run();
