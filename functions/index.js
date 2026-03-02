/**
 * Firebase Cloud Functions for Park Janana
 * Event-driven notifications only — no scheduled functions.
 *
 * Triggers:
 *  - onShiftWritten       shifts/{shiftId}   assigned / removed / rejected / message
 *  - onTaskCreated        tasks/{taskId}      newly assigned workers
 *  - onTaskWritten        tasks/{taskId}      new assignment / comment / status change
 *  - onNewUserPending     users/{userId}      new registration → notify managers
 *  - onUserUpdated        users/{userId}      worker approved / rejected
 *  - onPostWritten        posts/{postId}      new comment → notify post author
 *  - deletePost           callable            delete post (manager/owner/author)
 */

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ════════════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════════════

/**
 * Fetch FCM tokens for a user.
 * @param {string} userId
 * @returns {Promise<string[]>}
 */
async function getUserTokens(userId) {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) return [];
  return doc.data().fcmTokens || [];
}

/**
 * Fetch the full name of a user.
 * @param {string} userId
 * @returns {Promise<string>}
 */
async function getUserName(userId) {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) return "משתמש";
  return doc.data().fullName || "משתמש";
}

/**
 * Send FCM multicast and remove any invalid tokens from Firestore.
 * @param {string[]} tokens
 * @param {{ title: string, body: string }} notification
 * @param {Record<string, string>} data
 * @param {string} userId - owner of the tokens (for cleanup)
 */
async function sendNotification(tokens, notification, data = {}, userId = null) {
  if (!tokens || tokens.length === 0) return;

  // FCM data values must all be strings
  const stringData = {};
  for (const [k, v] of Object.entries(data)) {
    stringData[k] = String(v ?? "");
  }

  try {
    const response = await messaging.sendEachForMulticast({
      notification,
      data: stringData,
      tokens,
    });

    console.log(`FCM sent: ${response.successCount} ok, ${response.failureCount} failed`);

    // Remove invalid / expired tokens
    if (response.failureCount > 0 && userId) {
      const badTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            badTokens.push(tokens[idx]);
          }
          console.error(`Token ${idx} failed: ${code}`);
        }
      });
      if (badTokens.length > 0) {
        await db.collection("users").doc(userId).update({
          fcmTokens: FieldValue.arrayRemove(...badTokens),
        });
        console.log(`Removed ${badTokens.length} bad token(s) for ${userId}`);
      }
    }
  } catch (err) {
    console.error("sendNotification error:", err);
  }
}

/**
 * Write a notification document to users/{userId}/notifications.
 * This powers the in-app notification centre.
 * @param {string} userId
 * @param {{ type: string, title: string, body: string, entityId?: string, entityType?: string }} opts
 */
async function createUserNotification(userId, { type, title, body, entityId = "", entityType = "" }) {
  try {
    await db.collection("users").doc(userId)
      .collection("notifications").add({
        type,
        title,
        body,
        entityId,
        entityType,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    // Fire-and-forget: keep notification history under 30 days to prevent unbounded growth.
    pruneOldNotifications(userId).catch(console.error);
  } catch (err) {
    console.error(`createUserNotification error for ${userId}:`, err);
  }
}

/**
 * Delete notification documents older than 30 days (up to 50 at a time).
 * Called fire-and-forget after every createUserNotification write.
 * @param {string} userId
 */
async function pruneOldNotifications(userId) {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30);
  try {
    const snap = await db.collection("users").doc(userId)
      .collection("notifications")
      .where("createdAt", "<", cutoff)
      .limit(50)
      .get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    console.log(`Pruned ${snap.size} old notification(s) for ${userId}`);
  } catch (err) {
    console.error(`pruneOldNotifications error for ${userId}:`, err);
  }
}

/**
 * Send a push + write a Firestore notification record for one user.
 * @param {string} userId
 * @param {{ title: string, body: string }} notification
 * @param {{ type: string, entityId?: string, entityType?: string, [key: string]: any }} data
 */
async function notifyUser(userId, notification, data) {
  const tokens = await getUserTokens(userId);
  if (tokens.length > 0) {
    // Always embed recipientId so the Flutter app can verify the correct user
    // is logged in before navigating — prevents cross-user notification exploits.
    await sendNotification(tokens, notification, { ...data, recipientId: userId }, userId);
  }
  await createUserNotification(userId, {
    type: data.type,
    title: notification.title,
    body: notification.body,
    entityId: data.entityId || data.shiftId || data.taskId || data.userId || "",
    entityType: data.entityType || "",
  });
}

// ════════════════════════════════════════════════════════════════════════════
// SHIFT TRIGGER  (replaces onShiftUpdated + onShiftMessageAdded)
// ════════════════════════════════════════════════════════════════════════════

exports.onShiftWritten = onDocumentUpdated("shifts/{shiftId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const shiftId = event.params.shiftId;
  const department = after.department || "Unknown";
  const shiftDate = after.date || "";

  // ── 1. Newly assigned workers ──────────────────────────────────────────
  const prevAssigned = before.assignedWorkers || [];
  const nowAssigned = after.assignedWorkers || [];
  const newlyAssigned = nowAssigned.filter((uid) => !prevAssigned.includes(uid));

  for (const uid of newlyAssigned) {
    const startTime = after.startTime || "";
    const endTime = after.endTime || "";
    await notifyUser(
      uid,
      {
        title: "שובצת למשמרת! 🎉",
        body: `בתאריך ${shiftDate} בשעה ${startTime}–${endTime}`,
      },
      { type: "shift_assigned", entityId: shiftId, entityType: "shift", shiftId }
    );
  }

  // ── 2. Removed workers (was in assigned, now is not, and not rejected) ─
  const nowRejectedIds = (after.rejectedWorkerData || []).map((w) => w.userId);
  const removedWorkers = prevAssigned.filter(
    (uid) => !nowAssigned.includes(uid) && !nowRejectedIds.includes(uid)
  );

  for (const uid of removedWorkers) {
    await notifyUser(
      uid,
      {
        title: "הוסרת ממשמרת",
        body: `הוסרת מהמשמרת ב${department} בתאריך ${shiftDate}`,
      },
      { type: "shift_removed", entityId: shiftId, entityType: "shift", shiftId }
    );
  }

  // ── 3. Rejected workers ────────────────────────────────────────────────
  const prevRejected = (before.rejectedWorkerData || []).map((w) => w.userId);
  const newlyRejected = nowRejectedIds.filter((uid) => uid && !prevRejected.includes(uid));

  for (const uid of newlyRejected) {
    await notifyUser(
      uid,
      {
        title: "עדכון משמרת",
        body: `הבקשה שלך למשמרת ב${department} בתאריך ${shiftDate} לא אושרה`,
      },
      { type: "shift_rejected", entityId: shiftId, entityType: "shift", shiftId }
    );
  }

  // ── 4. New shift message ───────────────────────────────────────────────
  const prevMessages = before.messages || [];
  const nowMessages = after.messages || [];
  if (nowMessages.length > prevMessages.length) {
    const newMsg = nowMessages[nowMessages.length - 1];
    if (newMsg) {
      const senderId = newMsg.senderId || "";
      // Always fetch name from Firestore — never trust the client-supplied senderName field.
      const senderName = senderId ? await getUserName(senderId) : "מנהל";
      const msgText = newMsg.message || newMsg.text || "";
      const preview = msgText.length > 100 ? msgText.substring(0, 100) + "…" : msgText;

      for (const uid of nowAssigned) {
        if (uid === senderId) continue;
        await notifyUser(
          uid,
          {
            title: `${senderName} שלח הודעת משמרת 💬`,
            body: preview,
          },
          { type: "shift_message", entityId: shiftId, entityType: "shift", shiftId }
        );
      }
    }
  }
});

// ════════════════════════════════════════════════════════════════════════════
// TASK TRIGGER — created  (initial assignment)
// ════════════════════════════════════════════════════════════════════════════

exports.onTaskCreated = onDocumentCreated("tasks/{taskId}", async (event) => {
  const data = event.data.data();
  if (!data) return;

  const taskId = event.params.taskId;
  const taskTitle = data.title || "משימה חדשה";
  const assignedTo = data.assignedTo || [];

  for (const uid of assignedTo) {
    await notifyUser(
      uid,
      {
        title: "משימה חדשה! 📋",
        body: `קיבלת משימה חדשה: ${taskTitle}`,
      },
      { type: "task_assigned", entityId: taskId, entityType: "task", taskId }
    );
  }
});

// ════════════════════════════════════════════════════════════════════════════
// TASK TRIGGER — updated  (replaces onTaskUpdated + onTaskCommentAdded)
// ════════════════════════════════════════════════════════════════════════════

exports.onTaskWritten = onDocumentUpdated("tasks/{taskId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const taskId = event.params.taskId;
  const taskTitle = after.title || "משימה";
  const creatorId = after.createdBy || "";

  // ── 1. Newly assigned workers ──────────────────────────────────────────
  const prevAssigned = before.assignedTo || [];
  const nowAssigned = after.assignedTo || [];
  const newlyAssigned = nowAssigned.filter((uid) => !prevAssigned.includes(uid));

  for (const uid of newlyAssigned) {
    await notifyUser(
      uid,
      {
        title: "משימה חדשה! 📋",
        body: `קיבלת משימה חדשה: ${taskTitle}`,
      },
      { type: "task_assigned", entityId: taskId, entityType: "task", taskId }
    );
  }

  // ── 2. New comment ─────────────────────────────────────────────────────
  const prevComments = before.comments || [];
  const nowComments = after.comments || [];
  if (nowComments.length > prevComments.length) {
    const newComment = nowComments[nowComments.length - 1];
    if (newComment) {
      const commenterId = newComment.userId || newComment.by || "";
      // Always fetch name from Firestore — never trust the client-supplied userName field.
      const commenterName = commenterId ? await getUserName(commenterId) : "משתמש";
      const commentText = newComment.text || newComment.message || "";
      const preview = commentText.length > 80 ? commentText.substring(0, 80) + "…" : commentText;

      const recipients = new Set([...nowAssigned, creatorId]);
      recipients.delete(commenterId);

      for (const uid of recipients) {
        if (!uid) continue;
        await notifyUser(
          uid,
          {
            title: `${commenterName} הגיב על "${taskTitle}" 💬`,
            body: preview,
          },
          { type: "task_comment", entityId: taskId, entityType: "task", taskId }
        );
      }
    }
  }

  // ── 3. Worker changed their status → notify task creator ───────────────
  const prevProgress = before.workerProgress || {};
  const nowProgress = after.workerProgress || {};

  for (const [uid, nowEntry] of Object.entries(nowProgress)) {
    const prevEntry = prevProgress[uid] || {};
    const prevStatus = prevEntry.status || "pending";
    const nowStatus = nowEntry.status || "pending";

    if (prevStatus === nowStatus) continue;
    if (!creatorId || uid === creatorId) continue;

    // Worker submitted for manager review
    if (nowStatus === "pending_review") {
      const workerName = await getUserName(uid);
      await notifyUser(
        creatorId,
        {
          title: "משימה ממתינה לאישור 🔔",
          body: `${workerName} סיים את "${taskTitle}" וממתין לאישורך`,
        },
        { type: "task_review_requested", entityId: taskId, entityType: "task", taskId }
      );
    }

    // Manager approved the worker (done + approvedBy set)
    if (nowStatus === "done" && nowEntry.approvedBy && !prevEntry.approvedBy) {
      await notifyUser(
        uid,
        {
          title: "המשימה אושרה! ✅",
          body: `"${taskTitle}" אושרה על ידי המנהל`,
        },
        { type: "task_approved", entityId: taskId, entityType: "task", taskId }
      );
    }
  }
});

// ════════════════════════════════════════════════════════════════════════════
// USER CREATED — notify managers of pending registration
// ════════════════════════════════════════════════════════════════════════════

exports.onNewUserPending = onDocumentCreated("users/{userId}", async (event) => {
  const data = event.data.data();
  if (!data || data.approved === true) return;

  const newUserId = event.params.userId;
  const newUserName = data.fullName || "משתמש חדש";

  const managersSnap = await db.collection("users")
    .where("role", "in", ["manager", "admin", "owner"])
    .where("approved", "==", true)
    .get();

  for (const mgr of managersSnap.docs) {
    const tokens = mgr.data().fcmTokens || [];
    const mgrId = mgr.id;
    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "בקשת הרשמה חדשה 👤",
          body: `${newUserName} נרשם למערכת וממתין לאישור`,
        },
        { type: "new_user_pending", entityId: newUserId, entityType: "user", userId: newUserId, recipientId: mgrId },
        mgrId
      );
    }
    await createUserNotification(mgrId, {
      type: "new_user_pending",
      title: "בקשת הרשמה חדשה 👤",
      body: `${newUserName} נרשם למערכת וממתין לאישור`,
      entityId: newUserId,
      entityType: "user",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// USER UPDATED — worker approved or rejected by manager
// ════════════════════════════════════════════════════════════════════════════

exports.onUserUpdated = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const userId = event.params.userId;

  // ── Approved ───────────────────────────────────────────────────────────
  if (!before.approved && after.approved === true) {
    await notifyUser(
      userId,
      {
        title: "הבקשה שלך אושרה! 🎉",
        body: "ברוך הבא! חשבונך אושר ועכשיו תוכל להתחבר למערכת",
      },
      { type: "worker_approved", entityId: userId, entityType: "user" }
    );
  }

  // ── Rejected (rejectedAt field newly set) ─────────────────────────────
  if (!before.rejectedAt && after.rejectedAt) {
    await notifyUser(
      userId,
      {
        title: "עדכון בקשת הרשמה",
        body: "הבקשה שלך לא אושרה. לפרטים נוספים פנה למנהל",
      },
      { type: "worker_rejected", entityId: userId, entityType: "user" }
    );
  }
});

// ════════════════════════════════════════════════════════════════════════════
// POST UPDATED — new comment → notify post author
// ════════════════════════════════════════════════════════════════════════════

exports.onPostWritten = onDocumentUpdated("posts/{postId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const postId = event.params.postId;
  const authorId = after.authorId || "";
  if (!authorId) return;

  const prevComments = before.comments || [];
  const nowComments = after.comments || [];
  if (nowComments.length <= prevComments.length) return;

  const newComment = nowComments[nowComments.length - 1];
  if (!newComment) return;

  const commenterId = newComment.userId || "";
  if (commenterId === authorId) return; // Author commented on own post

  // Always fetch name from Firestore — never trust the client-supplied userName field.
  const commenterName = commenterId ? await getUserName(commenterId) : "משתמש";
  const commentText = newComment.content || newComment.text || "";
  const preview = commentText.length > 80 ? commentText.substring(0, 80) + "…" : commentText;
  const postTitle = after.title || "הפוסט שלך";

  await notifyUser(
    authorId,
    {
      title: `תגובה חדשה על "${postTitle}" 💬`,
      body: `${commenterName}: ${preview}`,
    },
    { type: "post_comment", entityId: postId, entityType: "post" }
  );
});

// ════════════════════════════════════════════════════════════════════════════
// CALLABLE — delete post (manager / owner / author)
// ════════════════════════════════════════════════════════════════════════════

exports.deletePost = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

  const { postId } = request.data;
  if (!postId) throw new HttpsError("invalid-argument", "postId is required");

  const postDoc = await db.collection("posts").doc(postId).get();
  if (!postDoc.exists) throw new HttpsError("not-found", "Post not found");

  const authorId = postDoc.data().authorId;
  const userDoc = await db.collection("users").doc(uid).get();
  const role = userDoc.exists ? userDoc.data().role : null;
  const canDelete = uid === authorId || role === "manager" || role === "owner";

  if (!canDelete) {
    throw new HttpsError("permission-denied", "Not authorized to delete this post");
  }

  await db.collection("posts").doc(postId).delete();
  console.log(`Post ${postId} deleted by ${uid} (role: ${role})`);
  return { success: true };
});
