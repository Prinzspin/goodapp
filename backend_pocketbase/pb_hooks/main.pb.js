// ========================================================
// HOOKS : GOOD APP (LOGIQUE MÉTIER & SÉCURITÉ)
// ========================================================

onRecordAfterCreateSuccess((e) => {
    try {
        const eventId = e.record.get("id");
        const creatorId = e.record.get("creator");

        // A. Créer la conversation (si pas déjà existante)
        const checkConv = $app.findRecordsByExpr("conversations", $dbx.exp("event = {:event}", { "event": eventId }));
        if (!checkConv || checkConv.length === 0) {
            const convCol = $app.findCollectionByNameOrId("conversations");
            const conversation = new Record(convCol);
            conversation.set("event", eventId);
            $app.save(conversation);
        }

        // B. Créer l'owner
        const checkMem = $app.findRecordsByExpr("event_members", $dbx.exp("event = {:event} AND user = {:user}", { "event": eventId, "user": creatorId }));
        if (!checkMem || checkMem.length === 0) {
            const memCol = $app.findCollectionByNameOrId("event_members");
            const member = new Record(memCol);
            member.set("event", eventId);
            member.set("user", creatorId);
            member.set("role", "owner");
            member.set("status", "accepted");
            $app.save(member);
        }
    } catch (err) {
        $app.logger().error("HOOK EVENT CREATE ERROR: " + err);
    }
}, "events");

function handleMembershipSync(record) {
    try {
        const eventId = record.get("event");
        const userId = record.get("user");
        const status = record.get("status");

        if (status === "accepted") {
            const parsedLikes = $app.findRecordsByExpr("event_likes", $dbx.exp("event = {:event} AND user = {:user}", {"event": eventId, "user": userId}));
            if (!parsedLikes || parsedLikes.length === 0) {
                 const likesCol = $app.findCollectionByNameOrId("event_likes");
                 const newLike = new Record(likesCol);
                 newLike.set("event", eventId);
                 newLike.set("user", userId);
                 $app.save(newLike);
            }
        }

        const acceptedMembers = $app.findRecordsByExpr("event_members", $dbx.exp("event = {:event} AND status = 'accepted'", {"event": eventId}));
        let acceptedCount = acceptedMembers ? acceptedMembers.length : 0;
        
        $app.db()
            .newQuery("UPDATE events SET members_count={:m} WHERE id={:id}")
            .bind({ "m": acceptedCount, "id": eventId }).execute();
    } catch (err) {
        $app.logger().error("HOOK MEMBERSHIP SYNC ERROR: " + err);
    }
}

onRecordAfterCreateSuccess((e) => { handleMembershipSync(e.record); }, "event_members");
onRecordAfterUpdateSuccess((e) => { handleMembershipSync(e.record); }, "event_members");

onRecordCreateRequest((e) => {
    let authorIdRaw = e.record.get("author");
    let conversationIdRaw = e.record.get("conversation");

    let authorId = Array.isArray(authorIdRaw) ? authorIdRaw[0] : String(authorIdRaw);
    let conversationId = Array.isArray(conversationIdRaw) ? conversationIdRaw[0] : String(conversationIdRaw);

    let eventId = "";
    try {
        const conversation = $app.findRecordById("conversations", conversationId);
        let eventIdRaw = conversation.get("event");
        eventId = Array.isArray(eventIdRaw) ? eventIdRaw[0] : String(eventIdRaw);
    } catch (err) {
        throw new BadRequestError("Conversation invalide.");
    }

    try {
        const result = new DynamicModel({ "id": "" });
        $app.db()
            .newQuery("SELECT id FROM event_members WHERE event={:event} AND user={:user} AND status='accepted' LIMIT 1")
            .bind({"event": eventId, "user": authorId})
            .one(result);
    } catch (err) {
        throw new BadRequestError("Accès refusé. Membership accepted requis.");
    }
    
    return e.next();
}, "messages");
