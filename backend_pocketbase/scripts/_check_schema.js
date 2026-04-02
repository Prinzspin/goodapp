import PocketBase from 'pocketbase';
const pb = new PocketBase("http://127.0.0.1:8090");
await pb.admins.authWithPassword("thomas.spinner0@gmail.com", "Inscriptio&1");
const r = await pb.collection("events").getList(1, 1);
if (r.items.length > 0) {
    const item = r.items[0];
    console.log("HAS lat:", "lat" in item);
    console.log("HAS lng:", "lng" in item);
    console.log("HAS long:", "long" in item);
    console.log("lat value:", item.lat);
    console.log("lng value:", item.lng);
    console.log("long value:", item.long);
    console.log("ALL KEYS:", Object.keys(item).join(", "));
} else { console.log("NO EVENTS"); }
