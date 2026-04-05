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
  if (!doc.exists) return { tokens: [], fullName: "משתמש", locale: "he" };
  const data = doc.data();
  return {
    tokens: data.fcmTokens || [],
    fullName: data.fullName || "משתמש",
    locale: data.locale || "he",
  };
}

// ── Notification string helpers ────────────────────────────────────────────

function t(locale, key, vars = {}) {
  const strings = {
    // Shift assigned
    shiftAssignedTitle: {
      en: "You've been assigned to a shift! 🎉",
      ar: "تم تعيينك في وردية! 🎉",
      he: "שובצת למשמרת! 🎉",
    },
    shiftAssignedBody: {
      en: `On ${vars.date} at ${vars.start}–${vars.end}`,
      ar: `بتاريخ ${vars.date} الساعة ${vars.start}–${vars.end}`,
      he: `בתאריך ${vars.date} בשעה ${vars.start}–${vars.end}`,
    },
    // Shift removed
    shiftRemovedTitle: {
      en: "Removed from shift",
      ar: "تمت إزالتك من الوردية",
      he: "הוסרת ממשמרת",
    },
    shiftRemovedBody: {
      en: `You were removed from the ${vars.dept} shift on ${vars.date}`,
      ar: `تمت إزالتك من وردية ${vars.dept} بتاريخ ${vars.date}`,
      he: `הוסרת מהמשמרת ב${vars.dept} בתאריך ${vars.date}`,
    },
    // Shift rejected
    shiftRejectedTitle: {
      en: "Shift request update",
      ar: "تحديث طلب الوردية",
      he: "עדכון משמרת",
    },
    shiftRejectedBody: {
      en: `Your request for the ${vars.dept} shift on ${vars.date} was not approved`,
      ar: `لم تتم الموافقة على طلبك لوردية ${vars.dept} بتاريخ ${vars.date}`,
      he: `הבקשה שלך למשמרת ב${vars.dept} בתאריך ${vars.date} לא אושרה`,
    },
    // Shift cancelled
    shiftCancelledTitle: {
      en: "Shift cancelled ❌",
      ar: "تم إلغاء الوردية ❌",
      he: "משמרת בוטלה ❌",
    },
    shiftCancelledBody: {
      en: `The ${vars.dept} shift on ${vars.date} was cancelled${vars.reason ? `: ${vars.reason}` : ""}`,
      ar: `تم إلغاء وردية ${vars.dept} بتاريخ ${vars.date}${vars.reason ? `: ${vars.reason}` : ""}`,
      he: `המשמרת ב${vars.dept} בתאריך ${vars.date} בוטלה${vars.reason ? `: ${vars.reason}` : ""}`,
    },
    // Shift reactivated
    shiftReactivatedTitle: {
      en: "Shift update 🔄",
      ar: "تحديث الوردية 🔄",
      he: "עדכון משמרת 🔄",
    },
    shiftReactivatedBody: {
      en: `The ${vars.dept} shift on ${vars.date} has been reactivated`,
      ar: `تم إعادة تفعيل وردية ${vars.dept} بتاريخ ${vars.date}`,
      he: `המשמרת ב${vars.dept} בתאריך ${vars.date} הופעלה מחדש`,
    },
    // Shift completed
    shiftCompletedTitle: {
      en: "Shift completed ✅",
      ar: "اكتملت الوردية ✅",
      he: "משמרת הושלמה ✅",
    },
    shiftCompletedBody: {
      en: `The ${vars.dept} shift on ${vars.date} has been marked as completed`,
      ar: `تم وضع علامة اكتمال على وردية ${vars.dept} بتاريخ ${vars.date}`,
      he: `המשמרת ב${vars.dept} בתאריך ${vars.date} סומנה כהושלמה`,
    },
    // Shift message
    shiftMessageTitle: {
      en: `${vars.sender} sent a shift message 💬`,
      ar: `${vars.sender} أرسل رسالة وردية 💬`,
      he: `${vars.sender} שלח הודעת משמרת 💬`,
    },
    // Task assigned
    taskAssignedTitle: {
      en: "New task! 📋",
      ar: "مهمة جديدة! 📋",
      he: "משימה חדשה! 📋",
    },
    taskAssignedBody: {
      en: `You have a new task: ${vars.title}`,
      ar: `لديك مهمة جديدة: ${vars.title}`,
      he: `קיבלת משימה חדשה: ${vars.title}`,
    },
    // Task comment
    taskCommentTitle: {
      en: `${vars.commenter} commented on "${vars.title}" 💬`,
      ar: `${vars.commenter} علّق على "${vars.title}" 💬`,
      he: `${vars.commenter} הגיב על "${vars.title}" 💬`,
    },
    // Task review requested
    taskReviewTitle: {
      en: "Task pending approval 🔔",
      ar: "مهمة في انتظار الموافقة 🔔",
      he: "משימה ממתינה לאישור 🔔",
    },
    taskReviewBody: {
      en: `${vars.worker} completed "${vars.title}" and is waiting for your approval`,
      ar: `${vars.worker} أنهى "${vars.title}" وينتظر موافقتك`,
      he: `${vars.worker} סיים את "${vars.title}" וממתין לאישורך`,
    },
    // Task approved
    taskApprovedTitle: {
      en: "Task approved! ✅",
      ar: "تمت الموافقة على المهمة! ✅",
      he: "המשימה אושרה! ✅",
    },
    taskApprovedBody: {
      en: `"${vars.title}" was approved by the manager`,
      ar: `تمت الموافقة على "${vars.title}" من قِبل المدير`,
      he: `"${vars.title}" אושרה על ידי המנהל`,
    },
    // Task rejected
    taskRejectedTitle: {
      en: "Task returned for revision 🔄",
      ar: "تمت إعادة المهمة للمراجعة 🔄",
      he: "המשימה הוחזרה לביצוע 🔄",
    },
    taskRejectedBody: {
      en: `"${vars.title}" was not approved by the manager — please continue working on it`,
      ar: `لم تتم الموافقة على "${vars.title}" من قِبل المدير — يرجى الاستمرار في تنفيذها`,
      he: `"${vars.title}" לא אושרה על ידי המנהל - יש להמשיך בביצוע`,
    },
    // New user pending
    newUserTitle: {
      en: "New registration request 👤",
      ar: "طلب تسجيل جديد 👤",
      he: "בקשת הרשמה חדשה 👤",
    },
    newUserBody: {
      en: `${vars.name} registered and is waiting for approval`,
      ar: `${vars.name} سجّل وينتظر الموافقة`,
      he: `${vars.name} נרשם למערכת וממתין לאישור`,
    },
    // Worker approved
    workerApprovedTitle: {
      en: "Your request was approved! 🎉",
      ar: "تمت الموافقة على طلبك! 🎉",
      he: "הבקשה שלך אושרה! 🎉",
    },
    workerApprovedBody: {
      en: "Welcome! Your account has been approved and you can now log in",
      ar: "مرحباً! تمت الموافقة على حسابك ويمكنك الآن تسجيل الدخول",
      he: "ברוך הבא! חשבונך אושר ועכשיו תוכל להתחבר למערכת",
    },
    // Worker registration rejected
    workerRejectedTitle: {
      en: "Registration request update",
      ar: "تحديث طلب التسجيل",
      he: "עדכון בקשת הרשמה",
    },
    workerRejectedBody: {
      en: "Your request was not approved. For more details contact the manager",
      ar: "لم تتم الموافقة على طلبك. للمزيد من التفاصيل تواصل مع المدير",
      he: "הבקשה שלך לא אושרה. לפרטים נוספים פנה למנהל",
    },
    // Post comment
    postCommentTitle: {
      en: `New comment on "${vars.postTitle}" 💬`,
      ar: `تعليق جديد على "${vars.postTitle}" 💬`,
      he: `תגובה חדשה על "${vars.postTitle}" 💬`,
    },
    postCommentBody: {
      en: `${vars.commenter}: ${vars.preview}`,
      ar: `${vars.commenter}: ${vars.preview}`,
      he: `${vars.commenter}: ${vars.preview}`,
    },
  };

  const entry = strings[key];
  if (!entry) return "";
  return entry[locale] || entry["he"] || "";
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
      newlyAssigned.map(async (uid) => {
        const { tokens, locale } = await getUserData(uid);
        return notifyUser(
          uid,
          {
            title: t(locale, "shiftAssignedTitle"),
            body: t(locale, "shiftAssignedBody", { date: shiftDate, start: startTime, end: endTime }),
          },
          { type: "shift_assigned", entityId: shiftId, entityType: "shift", shiftId },
          { tokens }
        );
      })
    );
  }

  // ── 2. Removed workers ─────────────────────────────────────────────────
  const nowRejectedIds = (after.rejectedWorkerData || []).map((w) => w.userId);
  const removedWorkers = prevAssigned.filter(
    (uid) => !nowAssigned.includes(uid) && !nowRejectedIds.includes(uid)
  );

  if (removedWorkers.length > 0) {
    await Promise.all(
      removedWorkers.map(async (uid) => {
        const { tokens, locale } = await getUserData(uid);
        return notifyUser(
          uid,
          {
            title: t(locale, "shiftRemovedTitle"),
            body: t(locale, "shiftRemovedBody", { dept: department, date: shiftDate }),
          },
          { type: "shift_removed", entityId: shiftId, entityType: "shift", shiftId },
          { tokens }
        );
      })
    );
  }

  // ── 3. Rejected workers ────────────────────────────────────────────────
  const prevRejected = (before.rejectedWorkerData || []).map((w) => w.userId);
  const newlyRejected = nowRejectedIds.filter((uid) => uid && !prevRejected.includes(uid));

  if (newlyRejected.length > 0) {
    await Promise.all(
      newlyRejected.map(async (uid) => {
        const { tokens, locale } = await getUserData(uid);
        return notifyUser(
          uid,
          {
            title: t(locale, "shiftRejectedTitle"),
            body: t(locale, "shiftRejectedBody", { dept: department, date: shiftDate }),
          },
          { type: "shift_rejected", entityId: shiftId, entityType: "shift", shiftId },
          { tokens }
        );
      })
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
      const workersToNotify = [...new Set([...assignedWorkers, ...requestedWorkers])];
      await Promise.all(
        workersToNotify.map(async (uid) => {
          const { tokens, locale } = await getUserData(uid);
          return notifyUser(
            uid,
            {
              title: t(locale, "shiftCancelledTitle"),
              body: t(locale, "shiftCancelledBody", { dept: department, date: shiftDate, reason: cancelReason }),
            },
            { type: "shift_cancelled", entityId: shiftId, entityType: "shift", shiftId },
            { tokens }
          );
        })
      );
    } else if (nowStatus === "active") {
      await Promise.all(
        assignedWorkers.map(async (uid) => {
          const { tokens, locale } = await getUserData(uid);
          return notifyUser(
            uid,
            {
              title: t(locale, "shiftReactivatedTitle"),
              body: t(locale, "shiftReactivatedBody", { dept: department, date: shiftDate }),
            },
            { type: "shift_update", entityId: shiftId, entityType: "shift", shiftId },
            { tokens }
          );
        })
      );
    } else if (nowStatus === "completed") {
      await Promise.all(
        assignedWorkers.map(async (uid) => {
          const { tokens, locale } = await getUserData(uid);
          return notifyUser(
            uid,
            {
              title: t(locale, "shiftCompletedTitle"),
              body: t(locale, "shiftCompletedBody", { dept: department, date: shiftDate }),
            },
            { type: "shift_update", entityId: shiftId, entityType: "shift", shiftId },
            { tokens }
          );
        })
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
      const senderData = senderId ? await getUserData(senderId) : { fullName: "מנהל", locale: "he" };
      const senderName = senderData.fullName;
      const msgText = newMsg.message || newMsg.text || "";
      const preview = msgText.length > 100 ? msgText.substring(0, 100) + "…" : msgText;

      const recipients = nowAssigned.filter((uid) => uid !== senderId);
      await Promise.all(
        recipients.map(async (uid) => {
          const { tokens, locale } = await getUserData(uid);
          return notifyUser(
            uid,
            {
              title: t(locale, "shiftMessageTitle", { sender: senderName }),
              body: preview,
            },
            { type: "shift_message", entityId: shiftId, entityType: "shift", shiftId },
            { tokens }
          );
        })
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
  const taskTitle = data.title || "";
  const assignedTo = data.assignedTo || [];

  await Promise.all(
    assignedTo.map(async (uid) => {
      const { tokens, locale } = await getUserData(uid);
      return notifyUser(
        uid,
        {
          title: t(locale, "taskAssignedTitle"),
          body: t(locale, "taskAssignedBody", { title: taskTitle }),
        },
        { type: "task_assigned", entityId: taskId, entityType: "task", taskId },
        { tokens }
      );
    })
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
      getUserData(uid).then(({ tokens, locale }) =>
        notifyUser(
          uid,
          {
            title: t(locale, "taskAssignedTitle"),
            body: t(locale, "taskAssignedBody", { title: taskTitle }),
          },
          { type: "task_assigned", entityId: taskId, entityType: "task", taskId },
          { tokens }
        )
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
      const commenterData = commenterId ? await getUserData(commenterId) : { fullName: "משתמש", locale: "he" };
      const commenterName = commenterData.fullName;
      const commentText = newComment.text || newComment.message || "";
      const preview = commentText.length > 80 ? commentText.substring(0, 80) + "…" : commentText;

      const recipients = new Set([...nowAssigned, creatorId]);
      recipients.delete(commenterId);

      for (const uid of recipients) {
        if (!uid) continue;
        notifications.push(
          getUserData(uid).then(({ tokens, locale }) =>
            notifyUser(
              uid,
              {
                title: t(locale, "taskCommentTitle", { commenter: commenterName, title: taskTitle }),
                body: preview,
              },
              { type: "task_comment", entityId: taskId, entityType: "task", taskId },
              { tokens }
            )
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
      const workerData = await getUserData(uid);
      const creatorData = await getUserData(creatorId);
      notifications.push(
        notifyUser(
          creatorId,
          {
            title: t(creatorData.locale, "taskReviewTitle"),
            body: t(creatorData.locale, "taskReviewBody", { worker: workerData.fullName, title: taskTitle }),
          },
          { type: "task_review_requested", entityId: taskId, entityType: "task", taskId },
          { tokens: creatorData.tokens }
        )
      );
    }

    if (nowStatus === "done" && nowEntry.approvedBy && !prevEntry.approvedBy) {
      notifications.push(
        getUserData(uid).then(({ tokens, locale }) =>
          notifyUser(
            uid,
            {
              title: t(locale, "taskApprovedTitle"),
              body: t(locale, "taskApprovedBody", { title: taskTitle }),
            },
            { type: "task_approved", entityId: taskId, entityType: "task", taskId },
            { tokens }
          )
        )
      );
    }

    if (nowStatus === "in_progress" && nowEntry.rejectedBy && !prevEntry.rejectedBy) {
      notifications.push(
        getUserData(uid).then(({ tokens, locale }) =>
          notifyUser(
            uid,
            {
              title: t(locale, "taskRejectedTitle"),
              body: t(locale, "taskRejectedBody", { title: taskTitle }),
            },
            { type: "task_rejected", entityId: taskId, entityType: "task", taskId },
            { tokens }
          )
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
      const mgrData = mgr.data();
      const tokens = mgrData.fcmTokens || [];
      const locale = mgrData.locale || "he";
      return notifyUser(
        mgrId,
        {
          title: t(locale, "newUserTitle"),
          body: t(locale, "newUserBody", { name: newUserName }),
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

  const { tokens, locale } = await getUserData(userId);

  // ── Approved ───────────────────────────────────────────────────────────
  if (!before.approved && after.approved === true) {
    await notifyUser(
      userId,
      {
        title: t(locale, "workerApprovedTitle"),
        body: t(locale, "workerApprovedBody"),
      },
      { type: "worker_approved", entityId: userId, entityType: "user" },
      { tokens }
    );
  }

  // ── Rejected (rejectedAt field newly set) ─────────────────────────────
  if (!before.rejectedAt && after.rejectedAt) {
    await notifyUser(
      userId,
      {
        title: t(locale, "workerRejectedTitle"),
        body: t(locale, "workerRejectedBody"),
      },
      { type: "worker_rejected", entityId: userId, entityType: "user" },
      { tokens }
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

  const commenterData = commenterId ? await getUserData(commenterId) : { fullName: "משתמש" };
  const commenterName = commenterData.fullName;
  const commentText = newComment.content || newComment.text || "";
  const preview = commentText.length > 80 ? commentText.substring(0, 80) + "…" : commentText;
  const postTitle = after.title || "";

  const { tokens: authorTokens, locale: authorLocale } = await getUserData(authorId);
  await notifyUser(
    authorId,
    {
      title: t(authorLocale, "postCommentTitle", { postTitle }),
      body: t(authorLocale, "postCommentBody", { commenter: commenterName, preview }),
    },
    { type: "post_comment", entityId: postId, entityType: "post" },
    { tokens: authorTokens }
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
