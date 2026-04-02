// ========================================================
// HOOKS : GOOD APP (LOGIQUE MÉTIER & SÉCURITÉ)
// ========================================================

onRecordAfterCreateSuccess((e) => {
    try {
        const eventId = e.record.get("id");
        const creatorId = e.record.get("creator");

        // A. Créer la conversation (si pas déjà existante)
        const checkConv = $app.dao().findRecordsByExpr("conversations", $dbx.exp("event = {:event}", { "event": eventId }));
        if (!checkConv || checkConv.length === 0) {
            const convCol = $app.dao().findCollectionByNameOrId("conversations");
            const conversation = new Record(convCol);
            conversation.set("event", eventId);
            $app.dao().saveRecord(conversation);
        }

        // B. Créer l'owner
        const checkMem = $app.dao().findRecordsByExpr("event_members", $dbx.exp("event = {:event} AND user = {:user}", { "event": eventId, "user": creatorId }));
        if (!checkMem || checkMem.length === 0) {
            const memCol = $app.dao().findCollectionByNameOrId("event_members");
            const member = new Record(memCol);
            member.set("event", eventId);
            member.set("user", creatorId);
            member.set("role", "owner");
            member.set("status", "accepted");
            $app.dao().saveRecord(member);
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
            const parsedLikes = $app.dao().findRecordsByExpr("event_likes", $dbx.exp("event = {:event} AND user = {:user}", {"event": eventId, "user": userId}));
            if (!parsedLikes || parsedLikes.length === 0) {
                 const likesCol = $app.dao().findCollectionByNameOrId("event_likes");
                 const newLike = new Record(likesCol);
                 newLike.set("event", eventId);
                 newLike.set("user", userId);
                 $app.dao().saveRecord(newLike);
            }
        }

        const acceptedMembers = $app.dao().findRecordsByExpr("event_members", $dbx.exp("event = {:event} AND status = 'accepted'", {"event": eventId}));
        let acceptedCount = acceptedMembers ? acceptedMembers.length : 0;
        
        $app.dao().db()
            .newQuery("UPDATE events SET members_count={:m} WHERE id={:id}")
            .bind({ "m": acceptedCount, "id": eventId }).execute();
    } catch (err) {
        $app.logger().error("HOOK MEMBERSHIP SYNC ERROR: " + err);
    }
}

onRecordAfterCreateSuccess((e) => { handleMembershipSync(e.record); }, "event_members");
onRecordAfterUpdateSuccess((e) => { handleMembershipSync(e.record); }, "event_members");

onRecordCreateRequest((e) => {
    try {
        const conversationId = e.record.get("conversation");
        const authorId = e.record.get("author");

        const conversation = $app.dao().findRecordById("conversations", conversationId);
        const eventId = conversation.get("event");

        const isMember = $app.dao().findRecordsByExpr("event_members", $dbx.exp("event = {:event} AND user = {:user} AND status = 'accepted'", { "event": eventId, "user": authorId }));
        
        if (!isMember || isMember.length === 0) {
            throw new Error("Non accepted.");
        }
    } catch (err) {
        throw new BadRequestError("Accès refusé. Membership accepted requis.");
    }
}, "messages");
