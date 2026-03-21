/**
 * Firebase Cloud Functions for Park Janana
 * Event-driven notifications only.
 *
 * Triggers:
 *  - onShiftWritten       shifts/{shiftId}   assigned / removed / rejected / message
 *  - onTaskCreated        tasks/{taskId}      newly assigned workers
 *  - onTaskWritten        tasks/{taskId}      new assignment / comment / status change
 *  - onNewUserPending     users/{userId}      new registration → notify managers
 *  - onUserUpdated        users/{userId}      worker approved / rejected
 *  - onPostWritten        posts/{postId}      new comment → notify post author
 *  - deletePost           callable            delete post (manager/owner/author)
 *  - pruneAllNotifications scheduled          daily cleanup of notifications older than 30 days
 */

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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
 * Fetch FCM tokens AND full name for a user in a single Firestore read.
 * Replaces the old separate getUserTokens() + getUserName() helpers which
 * caused two reads of the same document per notification.
 * @param {string} userId
 * @returns {Promise<{ tokens: string[], fullName: string }>}
 */
async function getUserData(userId) {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) return { tokens: [], fullName: "משתמש" };
  const data = doc.data();
  return {
    tokens: data.fcmTokens || [],
    fullName: data.fullName || "משתמש",
  };
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
 * NOTE: pruning is intentionally NOT called here — it runs on a daily
 * schedule (pruneAllNotifications) to avoid an extra Firestore read on
 * every notification write.
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
  } catch (err) {
    console.error(`createUserNotification error for ${userId}:`, err);
  }
}

/**
 * Send a push + write a Firestore notification record for one user.
 * @param {string} userId
 * @param {{ title: string, body: string }} notification
 * @param {{ type: string, entityId?: string, entityType?: string, [key: string]: any }} data
 * @param {{ tokens?: string[] }} [preloaded] - optional pre-fetched tokens to avoid
 *        an extra Firestore read (pass when the caller already has the user doc).
 */
async function notifyUser(userId, notification, data, preloaded = {}) {
  const tokens = preloaded.tokens !== undefined
    ? preloaded.tokens
    : (await getUserData(userId)).tokens;

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
// SHIFT TRIGGER
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

  if (newlyAssigned.length > 0) {
    const startTime = after.startTime || "";
    const endTime = after.endTime || "";
    await Promise.all(
      newlyAssigned.map((uid) =>
        notifyUser(
          uid,
          {
            title: "שובצת למשמרת! 🎉",
            body: `בתאריך ${shiftDate} בשעה ${startTime}–${endTime}`,
          },
          { type: "shift_assigned", entityId: shiftId, entityType: "shift", shiftId }
        )
      )
    );
  }

  // ── 2. Removed workers ─────────────────────────────────────────────────
  const nowRejectedIds = (after.rejectedWorkerData || []).map((w) => w.userId);
  const removedWorkers = prevAssigned.filter(
    (uid) => !nowAssigned.includes(uid) && !nowRejectedIds.includes(uid)
  );

  if (removedWorkers.length > 0) {
    await Promise.all(
      removedWorkers.map((uid) =>
        notifyUser(
          uid,
          {
            title: "הוסרת ממשמרת",
            body: `הוסרת מהמשמרת ב${department} בתאריך ${shiftDate}`,
          },
          { type: "shift_removed", entityId: shiftId, entityType: "shift", shiftId }
        )
      )
    );
  }

  // ── 3. Rejected workers ────────────────────────────────────────────────
  const prevRejected = (before.rejectedWorkerData || []).map((w) => w.userId);
  const newlyRejected = nowRejectedIds.filter((uid) => uid && !prevRejected.includes(uid));

  if (newlyRejected.length > 0) {
    await Promise.all(
      newlyRejected.map((uid) =>
        notifyUser(
          uid,
          {
            title: "עדכון משמרת",
            body: `הבקשה שלך למשמרת ב${department} בתאריך ${shiftDate} לא אושרה`,
          },
          { type: "shift_rejected", entityId: shiftId, entityType: "shift", shiftId }
        )
      )
    );
  }

  // ── 4. Shift status changed ────────────────────────────────────────────
  const prevStatus = before.status || "active";
  const nowStatus = after.status || "active";

  if (prevStatus !== nowStatus) {
    const assignedWorkers = after.assignedWorkers || [];
    const requestedWorkers = after.requestedWorkers || [];
    const cancelReason = after.cancelReason || "";

    if (nowStatus === "cancelled") {
      const bodyText = cancelReason
        ? `המשמרת ב${department} בתאריך ${shiftDate} בוטלה: ${cancelReason}`
        : `המשמרת ב${department} בתאריך ${shiftDate} בוטלה`;

      const workersToNotify = [...new Set([...assignedWorkers, ...requestedWorkers])];
      await Promise.all(
        workersToNotify.map((uid) =>
          notifyUser(
            uid,
            { title: "משמרת בוטלה ❌", body: bodyText },
            { type: "shift_cancelled", entityId: shiftId, entityType: "shift", shiftId }
          )
        )
      );
    } else if (nowStatus === "active") {
      await Promise.all(
        assignedWorkers.map((uid) =>
          notifyUser(
            uid,
            {
              title: "עדכון משמרת 🔄",
              body: `המשמרת ב${department} בתאריך ${shiftDate} הופעלה מחדש`,
            },
            { type: "shift_update", entityId: shiftId, entityType: "shift", shiftId }
          )
        )
      );
    } else if (nowStatus === "completed") {
      await Promise.all(
        assignedWorkers.map((uid) =>
          notifyUser(
            uid,
            {
              title: "משמרת הושלמה ✅",
              body: `המשמרת ב${department} בתאריך ${shiftDate} סומנה כהושלמה`,
            },
            { type: "shift_update", entityId: shiftId, entityType: "shift", shiftId }
          )
        )
      );
    }
  }

  // ── 5. New shift message ───────────────────────────────────────────────
  const prevMessages = before.messages || [];
  const nowMessages = after.messages || [];
  if (nowMessages.length > prevMessages.length) {
    const newMsg = nowMessages[nowMessages.length - 1];
    if (newMsg) {
      const senderId = newMsg.senderId || "";
      // Single getUserData call — gets both name and tokens if needed.
      // Never trust the client-supplied senderName field.
      const senderName = senderId ? (await getUserData(senderId)).fullName : "מנהל";
      const msgText = newMsg.message || newMsg.text || "";
      const preview = msgText.length > 100 ? msgText.substring(0, 100) + "…" : msgText;

      const recipients = nowAssigned.filter((uid) => uid !== senderId);
      await Promise.all(
        recipients.map((uid) =>
          notifyUser(
            uid,
            {
              title: `${senderName} שלח הודעת משמרת 💬`,
              body: preview,
            },
            { type: "shift_message", entityId: shiftId, entityType: "shift", shiftId }
          )
        )
      );
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

  await Promise.all(
    assignedTo.map((uid) =>
      notifyUser(
        uid,
        {
          title: "משימה חדשה! 📋",
          body: `קיבלת משימה חדשה: ${taskTitle}`,
        },
        { type: "task_assigned", entityId: taskId, entityType: "task", taskId }
      )
    )
  );
});

// ════════════════════════════════════════════════════════════════════════════
// TASK TRIGGER — updated
// ════════════════════════════════════════════════════════════════════════════

exports.onTaskWritten = onDocumentUpdated("tasks/{taskId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const taskId = event.params.taskId;
  const taskTitle = after.title || "משימה";
  const creatorId = after.createdBy || "";

  // Collect all notification promises and fire them together at the end
  const notifications = [];

  // ── 1. Newly assigned workers ──────────────────────────────────────────
  const prevAssigned = before.assignedTo || [];
  const nowAssigned = after.assignedTo || [];
  const newlyAssigned = nowAssigned.filter((uid) => !prevAssigned.includes(uid));

  for (const uid of newlyAssigned) {
    notifications.push(
      notifyUser(
        uid,
        {
          title: "משימה חדשה! 📋",
          body: `קיבלת משימה חדשה: ${taskTitle}`,
        },
        { type: "task_assigned", entityId: taskId, entityType: "task", taskId }
      )
    );
  }

  // ── 2. New comment ─────────────────────────────────────────────────────
  const prevComments = before.comments || [];
  const nowComments = after.comments || [];
  if (nowComments.length > prevComments.length) {
    const newComment = nowComments[nowComments.length - 1];
    if (newComment) {
      const commenterId = newComment.userId || newComment.by || "";
      // Single read for commenter name — never trust client-supplied userName.
      const commenterName = commenterId ? (await getUserData(commenterId)).fullName : "משתמש";
      const commentText = newComment.text || newComment.message || "";
      const preview = commentText.length > 80 ? commentText.substring(0, 80) + "…" : commentText;

      const recipients = new Set([...nowAssigned, creatorId]);
      recipients.delete(commenterId);

      for (const uid of recipients) {
        if (!uid) continue;
        notifications.push(
          notifyUser(
            uid,
            {
              title: `${commenterName} הגיב על "${taskTitle}" 💬`,
              body: preview,
            },
            { type: "task_comment", entityId: taskId, entityType: "task", taskId }
          )
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

    if (nowStatus === "pending_review") {
      const workerName = (await getUserData(uid)).fullName;
      notifications.push(
        notifyUser(
          creatorId,
          {
            title: "משימה ממתינה לאישור 🔔",
            body: `${workerName} סיים את "${taskTitle}" וממתין לאישורך`,
          },
          { type: "task_review_requested", entityId: taskId, entityType: "task", taskId }
        )
      );
    }

    if (nowStatus === "done" && nowEntry.approvedBy && !prevEntry.approvedBy) {
      notifications.push(
        notifyUser(
          uid,
          {
            title: "המשימה אושרה! ✅",
            body: `"${taskTitle}" אושרה על ידי המנהל`,
          },
          { type: "task_approved", entityId: taskId, entityType: "task", taskId }
        )
      );
    }

    if (nowStatus === "in_progress" && nowEntry.rejectedBy && !prevEntry.rejectedBy) {
      notifications.push(
        notifyUser(
          uid,
          {
            title: "המשימה הוחזרה לביצוע 🔄",
            body: `"${taskTitle}" לא אושרה על ידי המנהל - יש להמשיך בביצוע`,
          },
          { type: "task_rejected", entityId: taskId, entityType: "task", taskId }
        )
      );
    }
  }

  await Promise.all(notifications);
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

  // Notify all managers in parallel, passing their pre-fetched tokens to
  // avoid one extra user doc read per manager inside notifyUser.
  await Promise.all(
    managersSnap.docs.map((mgr) => {
      const mgrId = mgr.id;
      const tokens = mgr.data().fcmTokens || [];
      return notifyUser(
        mgrId,
        {
          title: "בקשת הרשמה חדשה 👤",
          body: `${newUserName} נרשם למערכת וממתין לאישור`,
        },
        { type: "new_user_pending", entityId: newUserId, entityType: "user", userId: newUserId },
        { tokens }
      );
    })
  );
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

  // Early exit: only process when a comment was actually added.
  // This prevents unnecessary function work on likes / reactions / pin changes.
  const prevComments = before.comments || [];
  const nowComments = after.comments || [];
  if (nowComments.length <= prevComments.length) return;

  const postId = event.params.postId;
  const authorId = after.authorId || "";
  if (!authorId) return;

  const newComment = nowComments[nowComments.length - 1];
  if (!newComment) return;

  const commenterId = newComment.userId || "";
  if (commenterId === authorId) return; // Author commented on own post

  // Single getUserData call — never trust the client-supplied userName field.
  const commenterName = commenterId ? (await getUserData(commenterId)).fullName : "משתמש";
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

// ════════════════════════════════════════════════════════════════════════════
// SCHEDULED — daily cleanup of notifications older than 30 days
//
// Runs once per day at 03:00 AM Asia/Jerusalem.
// Moved here from the per-notification createUserNotification path to avoid
// an extra Firestore read (prune query) on every notification write.
// ════════════════════════════════════════════════════════════════════════════

exports.pruneAllNotifications = onSchedule(
  { schedule: "0 3 * * *", timeZone: "Asia/Jerusalem" },
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    // Fetch only user IDs (no field data needed)
    const usersSnap = await db.collection("users").select().get();
    console.log(`pruneAllNotifications: checking ${usersSnap.size} users`);

    let totalPruned = 0;

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userId = userDoc.id;
        try {
          const snap = await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .where("createdAt", "<", cutoff)
            .limit(500)
            .get();

          if (snap.empty) return;

          // Delete in batches of 50 to stay well under Firestore limits
          const chunks = [];
          for (let i = 0; i < snap.docs.length; i += 50) {
            chunks.push(snap.docs.slice(i, i + 50));
          }
          await Promise.all(
            chunks.map((chunk) => {
              const batch = db.batch();
              chunk.forEach((doc) => batch.delete(doc.ref));
              return batch.commit();
            })
          );
          totalPruned += snap.size;
          console.log(`Pruned ${snap.size} notification(s) for ${userId}`);
        } catch (err) {
          console.error(`pruneAllNotifications error for ${userId}:`, err);
        }
      })
    );

    console.log(`pruneAllNotifications complete: ${totalPruned} total deleted`);
  }
);
