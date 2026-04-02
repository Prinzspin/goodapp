import PocketBase from 'pocketbase';
const pb = new PocketBase("http://127.0.0.1:8090");
async function run() {
    try {
        await pb.collection("users").authWithPassword("test@goodapp.com", "azertyuiop");
        const convs = await pb.collection("conversations").getFullList();
        if(convs.length === 0) return console.log("No conv");
        const myConv = convs[0];
        console.log("Sending to conv:", myConv.id);
        const res = await pb.collection("messages").create({
            "conversation": myConv.id,
            "author": pb.authStore.model.id,
            "content": "TEST"
        });
        console.log("SUCCESS!", res);
    } catch(e) {
        console.error("ERROR:");
        console.error(e.message);
        if(e.response) console.error(JSON.stringify(e.response, null, 2));
    }
}
run();
