import PocketBase from 'pocketbase';

async function testHook() {
  const pb = new PocketBase('http://127.0.0.1:8090');
  await pb.admins.authWithPassword("thomas.spinner0@gmail.com", "Inscriptio&1");
  try {
     const ev = await pb.collection('events').create({
         title: "Test Hook Method",
         description: "Testing findFirstRecordByFilter",
         start_date: new Date().toISOString(),
         creator: pb.authStore.model.id,
         is_public: true
     });
     console.log("Event created:", ev.id);
  } catch(e) { console.error(e.response); }
}
testHook();
