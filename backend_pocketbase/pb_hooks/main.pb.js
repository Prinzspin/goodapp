// ========================================================
// HOOKS : GOOD APP (LOGIQUE MÉTIER & SÉCURITÉ)
// Compatible PocketBase v0.23 (API sans dao(), sans findRecordsByExpr)
// ========================================================

onRecordAfterCreateSuccess((e) => {
    try {
        const eventId = e.record.get("id");
        const creatorId = e.record.get("creator");

        // A. Créer la conversation si elle n'existe pas
        const existingConvs = $app.findRecordsByFilter("conversations", `event = "${eventId}"`, "", 1, 0);
        if (!existingConvs || existingConvs.length === 0) {
            const convCol = $app.findCollectionByNameOrId("conversations");
            const conversation = new Record(convCol);
            conversation.set("event", eventId);
            $app.save(conversation);
        }

        // B. Créer le membership owner si absent
        const existingMem = $app.findRecordsByFilter("event_members", `event = "${eventId}" && user = "${creatorId}"`, "", 1, 0);
        if (!existingMem || existingMem.length === 0) {
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

        // Auto-like si le membre est accepted
        if (status === "accepted") {
            try {
                const existingLikes = $app.findRecordsByFilter("event_likes", `event = "${eventId}" && user = "${userId}"`, "", 1, 0);
                if (!existingLikes || existingLikes.length === 0) {
                    const likesCol = $app.findCollectionByNameOrId("event_likes");
                    const newLike = new Record(likesCol);
                    newLike.set("event", eventId);
                    newLike.set("user", userId);
                    $app.save(newLike);
                }
            } catch (likeErr) {
                $app.logger().error("HOOK LIKE SYNC WARNING (non-fatal): " + likeErr);
            }
        }

        // Mettre à jour members_count
        try {
            const countResult = new DynamicModel({ "cnt": 0 });
            $app.db()
                .newQuery(`SELECT COUNT(*) as cnt FROM event_members WHERE event="${eventId}" AND status='accepted'`)
                .one(countResult);
            const acceptedCount = countResult.get("cnt") || 0;
            $app.db()
                .newQuery("UPDATE events SET members_count={:m} WHERE id={:id}")
                .bind({ "m": acceptedCount, "id": eventId })
                .execute();
        } catch (countErr) {
            $app.logger().error("HOOK COUNT SYNC WARNING (non-fatal): " + countErr);
        }
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
