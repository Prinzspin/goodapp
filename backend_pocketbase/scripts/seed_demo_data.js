import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";
const GLOBAL_PASS = "azertyuiop";

const pb = new PocketBase(PB_URL);

const PARIS = [
    { lat: 48.8566, lng: 2.3522, name: "Île de la Cité" },
    { lat: 48.8606, lng: 2.3376, name: "Louvre" },
    { lat: 48.8530, lng: 2.3499, name: "Saint-Germain" },
    { lat: 48.8619, lng: 2.3323, name: "Tuileries" },
    { lat: 48.8867, lng: 2.3431, name: "Montmartre" },
    { lat: 48.8529, lng: 2.3692, name: "Bastille" },
    { lat: 48.8738, lng: 2.2950, name: "Arc de Triomphe" },
    { lat: 48.8584, lng: 2.2945, name: "Tour Eiffel" },
    { lat: 48.8462, lng: 2.3464, name: "Luxembourg" },
    { lat: 48.8649, lng: 2.3800, name: "République" },
    { lat: 48.8708, lng: 2.3051, name: "Parc Monceau" },
    { lat: 48.8443, lng: 2.3740, name: "Gare de Lyon" },
    { lat: 48.8530, lng: 2.3566, name: "Quartier Latin" },
    { lat: 48.8660, lng: 2.3619, name: "Marais" },
    { lat: 48.8768, lng: 2.3594, name: "Canal Saint-Martin" },
    { lat: 48.8810, lng: 2.3589, name: "Belleville" },
    { lat: 48.8490, lng: 2.3903, name: "Nation" },
    { lat: 48.8396, lng: 2.3825, name: "Bercy" },
    { lat: 48.8322, lng: 2.3561, name: "Place d'Italie" }
];

const TITLES = [
    "Afterwork Rooftop", "Yoga Sunrise", "Tech Meetup", "Brunch du Dimanche",
    "Pique-Nique Géant", "Dégustation Vins", "Running Matinal",
    "Atelier Photo", "Soirée Jazz", "Networking Devs",
    "Expo Street Art", "Concert Acoustique", "Dîner Secret",
    "Cours de Cuisine", "Tournoi Ping-Pong", "Spectacle Impro",
    "Ciné Plein Air", "Balade Vélo", "Apéro Jeux"
];

const MSGS = ["Salut à tous !", "Hâte d'y être !", "Quelqu'un connaît l'adresse ?",
    "Je ramène des boissons !", "C'est à quelle heure ?", "On se retrouve sur place !"];

async function seed() {
    try {
        await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
        console.log("OK auth");

        // CLEAN
        for (const col of ["messages", "conversations", "event_likes", "event_members", "events", "users"]) {
            const recs = await pb.collection(col).getFullList();
            for (const r of recs) await pb.collection(col).delete(r.id).catch(() => {});
        }
        console.log("OK clean");

        // USERS
        const testUser = await pb.collection("users").create({
            "email": "test@goodapp.com", "password": GLOBAL_PASS, "passwordConfirm": GLOBAL_PASS,
            "name": "Compte Test", "username": "tester", "bio": "Testeur officiel"
        });
        console.log("OK test user");

        const creators = [];
        for (let i = 1; i <= 10; i++) {
            const u = await pb.collection("users").create({
                "email": `creator${i}@demo.com`, "password": GLOBAL_PASS, "passwordConfirm": GLOBAL_PASS,
                "name": `Creator ${i}`, "username": `creator_${i}`
            });
            creators.push(u);
        }
        console.log("OK 10 creators");

        const participants = [];
        for (let i = 1; i <= 20; i++) {
            const u = await pb.collection("users").create({
                "email": `participant${i}@demo.com`, "password": GLOBAL_PASS, "passwordConfirm": GLOBAL_PASS,
                "name": `Participant ${i}`, "username": `participant_${i}`
            });
            participants.push(u);
        }
        console.log("OK 20 participants");

        // EVENTS (19 total)
        const events = [];
        for (let ci = 0; ci < creators.length; ci++) {
            const count = (ci % 3) + 1;
            for (let j = 0; j < count; j++) {
                const idx = events.length;
                if (idx >= PARIS.length) break;
                
                const isPublic = idx % 2 === 0;
                const loc = PARIS[idx];
                const d = new Date();
                d.setDate(d.getDate() + 5 + idx * 2);
                d.setHours(18 + (idx % 4), 0, 0, 0);

                const ev = await pb.collection("events").create({
                    "title": `${TITLES[idx]} @ ${loc.name}`,
                    "description": `Rejoignez-nous pour ${TITLES[idx].toLowerCase()} à ${loc.name}. Ambiance garantie !`,
                    "start_date": d.toISOString().replace('T', ' ').substring(0, 19) + 'Z',
                    "is_public": isPublic,
                    "creator": creators[ci].id,
                    "location_name": `${loc.name}, Paris`,
                    "lat": loc.lat,
                    "lng": loc.lng,
                    "likes_count": 0,
                    "members_count": 0
                });
                events.push({ id: ev.id, title: ev.title || TITLES[idx], _isPublic: isPublic });

                // EXPLICIT DB REPAIRS IN CASE HOOKS FAIL/SWALLOW:
                await pb.collection("conversations").create({ "event": ev.id }).catch(() => {});
                
                await pb.collection("event_members").create({
                    "event": ev.id,
                    "user": creators[ci].id,
                    "role": "owner",
                    "status": "accepted"
                }).catch(() => {});
            }
        }
        const publicEvents = events.filter(e => e._isPublic);
        console.log(`OK ${events.length} events (${publicEvents.length} pub, ${events.length - publicEvents.length} prv)`);

        // JOINS (20 participants × 2)
        const joinMap = {};
        for (let pi = 0; pi < participants.length; pi++) {
            const p = participants[pi];
            const e1 = publicEvents[pi % publicEvents.length];
            const e2 = publicEvents[(pi + 1) % publicEvents.length];
            const joined = [e1.id];

            await pb.collection("event_members").create(
                { "event": e1.id, "user": p.id, "status": "accepted", "role": "member" }
            ).catch(() => {});

            if (e2.id !== e1.id) {
                joined.push(e2.id);
                await pb.collection("event_members").create(
                    { "event": e2.id, "user": p.id, "status": "accepted", "role": "member" }
                ).catch(() => {});
            }
            joinMap[p.id] = joined;

            for (const eid of joined) {
                await pb.collection("event_likes").create({ "event": eid, "user": p.id }).catch(() => {});
            }
        }
        console.log("OK joins");

        // LIKES SANS JOIN
        const allIds = events.map(e => e.id);
        let extraLikes = 0;
        for (let pi = 0; pi < participants.length; pi++) {
            const p = participants[pi];
            const joined = joinMap[p.id] || [];
            const available = allIds.filter(id => !joined.includes(id));
            const count = (pi % 2 === 0) ? 2 : 3;
            for (let k = 0; k < count && k < available.length; k++) {
                await pb.collection("event_likes").create(
                    { "event": available[(pi + k) % available.length], "user": p.id }
                ).catch(() => {});
                extraLikes++;
            }
        }
        console.log(`OK ${extraLikes} extra likes`);

        // TEST USER
        const testJoin = publicEvents[0];
        const testLike = events.find(e => e.id !== testJoin.id);
        await pb.collection("event_members").create(
            { "event": testJoin.id, "user": testUser.id, "status": "accepted", "role": "member" }
        ).catch(() => {});
        await pb.collection("event_likes").create({ "event": testJoin.id, "user": testUser.id }).catch(() => {});
        await pb.collection("event_likes").create({ "event": testLike.id, "user": testUser.id }).catch(() => {});
        console.log("OK test user actions");

        // COUNTERS
        for (const ev of events) {
            const mc = await pb.collection("event_members").getList(1, 1, { filter: `event="${ev.id}" && status="accepted"` });
            const lc = await pb.collection("event_likes").getList(1, 1, { filter: `event="${ev.id}"` });
            await pb.collection("events").update(ev.id, { "members_count": mc.totalItems, "likes_count": lc.totalItems }).catch(() => {});
        }
        console.log("OK counters");

        // MESSAGES
        try {
             const convs = await pb.collection("conversations").getFullList();
             for (const conv of convs) {
                 const mems = await pb.collection("event_members").getFullList({ filter: `event="${conv.event}" && status="accepted"` });
                 if (mems.length >= 2) {
                     for (let i = 0; i < 3; i++) {
                         await pb.collection("messages").create({
                             "conversation": conv.id, "author": mems[i % mems.length].user, "content": MSGS[i]
                         }).catch(() => {});
                     }
                 }
             }
             console.log("OK messages");
        } catch(e) {
             console.log("Messages warn:", e.message);
        }

        console.log("\nDONE!");
        console.log(`Users: 31 | Events: ${events.length} | Pub: ${publicEvents.length} | Prv: ${events.length - publicEvents.length}`);
        console.log(`Extra likes: ${extraLikes} | Password: ${GLOBAL_PASS}`);

    } catch (e) {
        console.error("FATAL:", e.message);
        console.error("Response data:", e.response?.data);
        console.error("Full error:", e);
    }
}

seed();
