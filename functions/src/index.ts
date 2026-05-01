import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

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
      body = `📍 ${msg.content}`;
    } else if (type === "Shopping") {
      body = "Added to shopping list";
    } else {
      body = "Sent a message";
    }

    // Get family members
    const familySnap = await admin.firestore().doc(`families/${familyId}`).get();
    const members: Array<{ id: string }> = familySnap.data()?.members ?? [];

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
      notification: { title: senderName, body },
      data: { familyId, type },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    });
  });
