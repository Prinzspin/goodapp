import PocketBase from 'pocketbase';

const PB_URL = "http://127.0.0.1:8090";
const ADMIN_EMAIL = "thomas.spinner0@gmail.com";
const ADMIN_PASS = "Inscriptio&1";
const GLOBAL_PASS = "azertyuiop";

async function debug() {
    const pb = new PocketBase(PB_URL);
    await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASS);
    
    const events = await pb.collection('events').getFullList();
    if (events.length === 0) {
        console.log("No events found.");
        return;
    }

    const testEvent = events[0];
    console.log("Testing with event:", testEvent.id);

    // Get the creator
    const creatorUser = await pb.collection('users').getOne(testEvent.creator);
    console.log("Creator ID:", creatorUser.id);
    
    // Auth as creator
    pb.authStore.clear();
    await pb.collection('users').authWithPassword(creatorUser.email, GLOBAL_PASS);

    // Simulate flutter chat_repository.dart logic
    try {
        console.log("Fetching conversation for event:", testEvent.id);
        const record = await pb.collection('conversations').getFirstListItem(`event="${testEvent.id}"`, {
            expand: 'event,event.creator'
        });
        console.log("SUCCESS! Conversation ID:", record.id);
    } catch (e) {
        console.error("FAIL! Error fetching conversation:", e.status, e.message);
    }
}

debug();
