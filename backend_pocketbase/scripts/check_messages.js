import PocketBase from 'pocketbase';
const pb = new PocketBase("http://127.0.0.1:8090");
async function run() {
    await pb.collection("users").authWithPassword("test@goodapp.com", "azertyuiop");
    const msgs = await pb.collection("messages").getFullList({ sort: '-created', perPage: 5 });
    console.log("Total messages in collection:", msgs.length);
    for (const m of msgs) {
        console.log(" ->", m.id, "|", m.content, "|", m.conversation, "|", m.created);
    }
}
run();
