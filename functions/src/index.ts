import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// --- Shared notification helpers ---

/** FCM tokens for the given member ids, optionally excluding one (e.g. the actor). */
async function fcmTokens(memberIds: string[], excludeId?: string): Promise<string[]> {
  const ids = memberIds.filter((id) => id !== excludeId);
  if (ids.length === 0) return [];
  const snaps = await Promise.all(ids.map((id) => admin.firestore().doc(`users/${id}`).get()));
  return snaps
    .map((s) => s.data()?.fcmToken as string | undefined)
    .filter((t): t is string => Boolean(t));
}

async function notify(
  tokens: string[],
  title: string,
  body: string,
  data: { [k: string]: string }
): Promise<void> {
  if (tokens.length === 0) return;
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    apns: { payload: { aps: { sound: "default", badge: 1 } } },
  });
}

export const onNewMessage = functions.firestore
  .document("families/{familyId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    if (!msg || msg.type === "system") return;

    const { familyId } = context.params;
    const senderId: string = msg.senderID;
    const senderName: string = msg.senderName ?? "Someone";
    const type: string = msg.type;

    let body: string;
    if (type === "ping") {
      // ping content is E2E-encrypted, so the server can't read it.
      body = "📍 Shared their status";
    } else if (type === "Shopping") {
      body = "Added to shopping list";
    } else if (type === "photo") {
      body = "📷 Sent a photo";
    } else {
      body = "Sent a message";
    }

    // Get family members
    const familySnap = await admin
      .firestore()
      .doc(`families/${familyId}`)
      .get();
    const members: Array<{ id: string }> = familySnap.data()?.members ?? [];
    const familyName: string = familySnap.data()?.name ?? "";

    // Collect FCM tokens of all members except the sender
    const tokenFetches = members
      .filter((m) => m.id !== senderId)
      .map((m) => admin.firestore().doc(`users/${m.id}`).get());

    const userSnaps = await Promise.all(tokenFetches);
    const tokens: string[] = userSnaps
      .map((s) => s.data()?.fcmToken as string | undefined)
      .filter((t): t is string => Boolean(t));

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: familyName ? `${senderName} · ${familyName}` : senderName,
        body,
      },
      data: { familyId, type },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    });
  });

// Safety net: when a family doc is deleted (the last member leaves and the
// client wipes the group), sweep up anything the client couldn't reach — the
// messages subcollection and the encrypted photo blobs in Storage. Runs with
// the Admin SDK. No-op if the client already cleaned everything.
export const onFamilyDeleted = functions.firestore
  .document("families/{familyId}")
  .onDelete(async (snap, context) => {
    const { familyId } = context.params;
    const db = admin.firestore();

    // 1. Delete any leftover messages in the (now-orphaned) subcollection.
    try {
      await db.recursiveDelete(db.collection(`families/${familyId}/messages`));
    } catch (e) {
      console.error(`Failed to delete messages for family ${familyId}`, e);
    }

    // 2. Delete any leftover encrypted photo blobs.
    try {
      await admin
        .storage()
        .bucket()
        .deleteFiles({
          prefix: `families/${familyId}/photos/`,
        });
    } catch (e) {
      console.error(`Failed to delete photos for family ${familyId}`, e);
    }
  });

// Notify family members when a new calendar event is created. The title is
// E2E-encrypted (server can't read it), so the body is intentionally generic.
export const onNewEvent = functions.firestore
  .document("families/{familyId}/events/{eventId}")
  .onCreate(async (snap, context) => {
    const event = snap.data();
    if (!event) return;

    const { familyId } = context.params;
    const creatorId: string = event.createdBy;
    const creatorName: string = event.createdByName ?? "Someone";

    const familySnap = await admin
      .firestore()
      .doc(`families/${familyId}`)
      .get();
    const members: Array<{ id: string }> = familySnap.data()?.members ?? [];
    const familyName: string = familySnap.data()?.name ?? "";

    const userSnaps = await Promise.all(
      members
        .filter((m) => m.id !== creatorId)
        .map((m) => admin.firestore().doc(`users/${m.id}`).get()),
    );
    const tokens: string[] = userSnaps
      .map((s) => s.data()?.fcmToken as string | undefined)
      .filter((t): t is string => Boolean(t));

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: familyName ? `${creatorName} · ${familyName}` : creatorName,
        body: "📅 Added a new event",
      },
      data: { familyId, type: "event" },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  });

// Notify members when a message is pinned (pins are high-signal by definition).
export const onMessagePinned = functions.firestore
  .document("families/{familyId}/messages/{messageId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Only on the false -> true transition (ignore reaction edits etc.).
    if (before?.isPinned === true || after?.isPinned !== true) return;

    const { familyId } = context.params;
    const pinnedBy: string = after.pinnedBy ?? "";
    const pinnedByName: string = after.pinnedByName ?? "Someone";

    const familySnap = await admin.firestore().doc(`families/${familyId}`).get();
    const memberIds: string[] = familySnap.data()?.memberIds ?? [];
    const familyName: string = familySnap.data()?.name ?? "";

    const tokens = await fcmTokens(memberIds, pinnedBy);
    await notify(
      tokens,
      familyName ? `${pinnedByName} · ${familyName}` : pinnedByName,
      "📌 Pinned a message",
      { familyId, type: "pin" }
    );
  });

// Notify when someone joins or leaves the family.
export const onMembershipChange = functions.firestore
  .document("families/{familyId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const beforeIds: string[] = before?.memberIds ?? [];
    const afterIds: string[] = after?.memberIds ?? [];
    if (beforeIds.length === afterIds.length) return; // membership unchanged

    const { familyId } = context.params;
    const familyName: string = after?.name ?? "Huddle";

    if (afterIds.length > beforeIds.length) {
      const joinedId = afterIds.find((id) => !beforeIds.includes(id));
      if (!joinedId) return;
      const members: Array<{ id: string; displayName?: string }> = after?.members ?? [];
      const name = members.find((m) => m.id === joinedId)?.displayName ?? "Someone";
      const tokens = await fcmTokens(beforeIds); // existing members
      await notify(tokens, familyName, `👋 ${name} joined`, { familyId, type: "join" });
    } else {
      const leftId = beforeIds.find((id) => !afterIds.includes(id));
      if (!leftId) return;
      const members: Array<{ id: string; displayName?: string }> = before?.members ?? [];
      const name = members.find((m) => m.id === leftId)?.displayName ?? "Someone";
      const tokens = await fcmTokens(afterIds); // remaining members
      await notify(tokens, familyName, `👋 ${name} left`, { familyId, type: "leave" });
    }
  });

// Notify the event creator when someone RSVPs to their event.
export const onEventRSVP = functions.firestore
  .document("families/{familyId}/events/{eventId}")
  .onUpdate(async (change, context) => {
    const beforeR: { [k: string]: string } = change.before.data()?.rsvps ?? {};
    const afterR: { [k: string]: string } = change.after.data()?.rsvps ?? {};

    let changedUser: string | undefined;
    for (const uid of Object.keys(afterR)) {
      if (afterR[uid] !== beforeR[uid]) { changedUser = uid; break; }
    }
    if (!changedUser) return;

    const creatorId: string = change.after.data()?.createdBy;
    if (!creatorId || creatorId === changedUser) return; // skip self-RSVP

    const { familyId } = context.params;
    const creatorSnap = await admin.firestore().doc(`users/${creatorId}`).get();
    const token = creatorSnap.data()?.fcmToken as string | undefined;
    if (!token) return;

    const familySnap = await admin.firestore().doc(`families/${familyId}`).get();
    const members: Array<{ id: string; displayName?: string }> = familySnap.data()?.members ?? [];
    const name = members.find((m) => m.id === changedUser)?.displayName ?? "Someone";
    const familyName: string = familySnap.data()?.name ?? "Huddle";

    const status = afterR[changedUser];
    const verb = status === "going" ? "is going to" : status === "maybe" ? "might come to" : "can’t make";
    await notify([token], familyName, `${name} ${verb} your event`, { familyId, type: "rsvp" });
  });
