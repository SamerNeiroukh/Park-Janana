/**
 * Firebase Cloud Functions for Park Janana
 * Handles push notifications for:
 * - Shift assignments
 * - Task assignments
 * - New messages in shifts
 */

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Helper: Get FCM tokens for a user
 * @param {string} userId - The user's UID
 * @returns {Promise<string[]>} Array of FCM tokens
 */
async function getUserTokens(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) return [];

  const userData = userDoc.data();
  return userData.fcmTokens || [];
}

/**
 * Helper: Get user's full name
 * @param {string} userId - The user's UID
 * @returns {Promise<string>} User's full name
 */
async function getUserName(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) return "Unknown";

  const userData = userDoc.data();
  return userData.fullName || "Unknown";
}

/**
 * Helper: Send notification to multiple tokens
 * @param {string[]} tokens - FCM tokens
 * @param {object} notification - Notification payload
 * @param {object} data - Data payload
 */
async function sendNotification(tokens, notification, data = {}) {
  if (!tokens || tokens.length === 0) {
    console.log("No tokens to send notification to");
    return;
  }

  const message = {
    notification,
    data,
    tokens,
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`Successfully sent ${response.successCount} messages`);

    // Handle failed tokens (remove invalid ones)
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          console.error(`Failed to send to token: ${resp.error}`);
        }
      });
      // TODO: Remove failed tokens from Firestore
    }
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

/**
 * Trigger: When a shift document is updated
 * Sends notifications when:
 * - Worker is assigned to a shift (added to assignedWorkers)
 * - Worker is rejected from a shift
 */
exports.onShiftUpdated = onDocumentUpdated("shifts/{shiftId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) return;

  const shiftId = event.params.shiftId;
  const shiftDate = afterData.date || "Unknown date";
  const department = afterData.department || "Unknown";

  // Check for newly assigned workers
  const beforeAssigned = beforeData.assignedWorkers || [];
  const afterAssigned = afterData.assignedWorkers || [];

  const newlyAssigned = afterAssigned.filter(
    (uid) => !beforeAssigned.includes(uid)
  );

  // Send notification to newly assigned workers
  for (const userId of newlyAssigned) {
    const tokens = await getUserTokens(userId);
    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "שובצת למשמרת! 🎉",
          body: `שובצת למשמרת ב${department} בתאריך ${shiftDate}`,
        },
        {
          type: "shift_assigned",
          shiftId: shiftId,
        }
      );
    }
  }

  // Check for rejected workers
  const beforeRejected = (beforeData.rejectedWorkerData || []).map(
    (w) => w.userId
  );
  const afterRejected = (afterData.rejectedWorkerData || []).map(
    (w) => w.userId
  );

  const newlyRejected = afterRejected.filter(
    (uid) => uid && !beforeRejected.includes(uid)
  );

  // Send notification to rejected workers
  for (const odekId of newlyRejected) {
    // Find the actual user ID from the rejected data
    const rejectedWorker = afterData.rejectedWorkerData.find(
      (w) => w.userId === odekId
    );
    if (!rejectedWorker) continue;

    const tokens = await getUserTokens(odekId);
    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "עדכון משמרת",
          body: `הבקשה שלך למשמרת ב${department} בתאריך ${shiftDate} לא אושרה`,
        },
        {
          type: "shift_rejected",
          shiftId: shiftId,
        }
      );
    }
  }
});

/**
 * Trigger: When a task document is updated
 * Sends notifications when:
 * - Worker is assigned to a task (added to assignedTo)
 * - Task status changes for a specific worker
 */
exports.onTaskUpdated = onDocumentUpdated("tasks/{taskId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) return;

  const taskId = event.params.taskId;
  const taskTitle = afterData.title || "משימה חדשה";

  // Check for newly assigned workers
  const beforeAssigned = beforeData.assignedTo || [];
  const afterAssigned = afterData.assignedTo || [];

  const newlyAssigned = afterAssigned.filter(
    (uid) => !beforeAssigned.includes(uid)
  );

  // Send notification to newly assigned workers
  for (const userId of newlyAssigned) {
    const tokens = await getUserTokens(userId);
    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "משימה חדשה! 📋",
          body: `קיבלת משימה חדשה: ${taskTitle}`,
        },
        {
          type: "task_assigned",
          taskId: taskId,
        }
      );
    }
  }
});

/**
 * Trigger: When a shift's messages are updated
 * Sends notifications when a new message is added to a shift
 */
exports.onShiftMessageAdded = onDocumentUpdated(
  "shifts/{shiftId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) return;

    const shiftId = event.params.shiftId;
    const beforeMessages = beforeData.messages || [];
    const afterMessages = afterData.messages || [];

    // Check if a new message was added
    if (afterMessages.length <= beforeMessages.length) return;

    // Get the new message (last one in the array)
    const newMessage = afterMessages[afterMessages.length - 1];
    if (!newMessage) return;

    const senderId = newMessage.senderId;
    const senderName = newMessage.senderName || await getUserName(senderId) || "מנהל";
    const messageText = newMessage.message || newMessage.text || "";

    // Get all assigned workers
    const assignedWorkers = afterData.assignedWorkers || [];

    // Send notification to all assigned workers except the sender
    for (const userId of assignedWorkers) {
      if (userId === senderId) continue; // Don't notify the sender

      const tokens = await getUserTokens(userId);
      if (tokens.length > 0) {
        await sendNotification(
          tokens,
          {
            title: `הודעה חדשה מ${senderName} 💬`,
            body: messageText.length > 100
              ? messageText.substring(0, 100) + "..."
              : messageText,
          },
          {
            type: "shift_message",
            shiftId: shiftId,
          }
        );
      }
    }
  }
);

/**
 * Trigger: When a task's comments are updated
 * Sends notifications when a new comment is added to a task
 */
exports.onTaskCommentAdded = onDocumentUpdated(
  "tasks/{taskId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) return;

    const taskId = event.params.taskId;
    const beforeComments = beforeData.comments || [];
    const afterComments = afterData.comments || [];

    // Check if a new comment was added
    if (afterComments.length <= beforeComments.length) return;

    // Get the new comment (last one in the array)
    const newComment = afterComments[afterComments.length - 1];
    if (!newComment) return;

    const commenterId = newComment.userId || newComment.by;
    const commenterName = newComment.userName || (commenterId ? await getUserName(commenterId) : "משתמש");
    const commentText = newComment.text || newComment.message || "";
    const taskTitle = afterData.title || "משימה";

    // Get all assigned workers and the creator
    const assignedWorkers = afterData.assignedTo || [];
    const creatorId = afterData.createdBy;

    // Combine all users who should be notified
    const usersToNotify = new Set([...assignedWorkers, creatorId]);
    usersToNotify.delete(commenterId); // Don't notify the commenter

    // Send notification to all relevant users
    for (const userId of usersToNotify) {
      if (!userId) continue;

      const tokens = await getUserTokens(userId);
      if (tokens.length > 0) {
        await sendNotification(
          tokens,
          {
            title: `תגובה חדשה ב${taskTitle} 💬`,
            body: `${commenterName}: ${
              commentText.length > 80
                ? commentText.substring(0, 80) + "..."
                : commentText
            }`,
          },
          {
            type: "task_comment",
            taskId: taskId,
          }
        );
      }
    }
  }
);

/**
 * Trigger: When a new task is created
 * Sends notifications to all assigned workers
 */
exports.onTaskCreated = onDocumentCreated("tasks/{taskId}", async (event) => {
  const taskData = event.data.data();
  if (!taskData) return;

  const taskId = event.params.taskId;
  const taskTitle = taskData.title || "משימה חדשה";
  const assignedTo = taskData.assignedTo || [];

  // Send notification to all assigned workers
  for (const userId of assignedTo) {
    const tokens = await getUserTokens(userId);
    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "משימה חדשה! 📋",
          body: `קיבלת משימה חדשה: ${taskTitle}`,
        },
        {
          type: "task_assigned",
          taskId: taskId,
        }
      );
    }
  }
});

/**
 * Trigger: When a new user is created (pending approval)
 * Sends notification to all managers
 */
exports.onNewUserPending = onDocumentCreated("users/{userId}", async (event) => {
  const userData = event.data.data();
  if (!userData) return;

  // Only notify if user is not approved (pending)
  if (userData.approved === true) return;

  const newUserName = userData.fullName || "משתמש חדש";

  // Get all managers and admins
  const managersQuery = await db.collection("users")
    .where("role", "in", ["manager", "admin"])
    .where("approved", "==", true)
    .get();

  // Send notification to each manager
  for (const managerDoc of managersQuery.docs) {
    const managerData = managerDoc.data();
    const tokens = managerData.fcmTokens || [];

    if (tokens.length > 0) {
      await sendNotification(
        tokens,
        {
          title: "בקשת הרשמה חדשה 👤",
          body: `${newUserName} נרשם למערכת וממתין לאישור`,
        },
        {
          type: "new_user_pending",
          userId: event.params.userId,
        }
      );
    }
  }
});

/**
 * Helper: Parse date string (dd/MM/yyyy) and time string (HH:mm) to Date
 */
function parseShiftDateTime(dateStr, timeStr) {
  if (!dateStr || !timeStr) return null;

  const [day, month, year] = dateStr.split("/").map(Number);
  const [hours, minutes] = timeStr.split(":").map(Number);

  if (!day || !month || !year || isNaN(hours) || isNaN(minutes)) return null;

  return new Date(year, month - 1, day, hours, minutes);
}

/**
 * Scheduled: Run every 15 minutes to check for shifts starting in ~1 hour
 * Sends reminder notifications to assigned workers
 */
exports.shiftReminder = onSchedule("every 15 minutes", async (event) => {
  const now = new Date();
  const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
  const oneHour15Later = new Date(now.getTime() + 75 * 60 * 1000);

  // Format today's date as dd/MM/yyyy for query
  const todayStr = `${String(now.getDate()).padStart(2, "0")}/${String(now.getMonth() + 1).padStart(2, "0")}/${now.getFullYear()}`;

  // Get all shifts for today
  const shiftsQuery = await db.collection("shifts")
    .where("date", "==", todayStr)
    .get();

  for (const shiftDoc of shiftsQuery.docs) {
    const shiftData = shiftDoc.data();
    const shiftId = shiftDoc.id;

    // Check if we already sent a reminder for this shift
    if (shiftData.reminderSent === true) continue;

    const shiftDateTime = parseShiftDateTime(shiftData.date, shiftData.startTime);
    if (!shiftDateTime) continue;

    // Check if shift starts within the next 60-75 minutes
    if (shiftDateTime >= oneHourLater && shiftDateTime <= oneHour15Later) {
      const department = shiftData.department || "Unknown";
      const startTime = shiftData.startTime || "";
      const assignedWorkers = shiftData.assignedWorkers || [];

      // Send reminder to all assigned workers
      for (const userId of assignedWorkers) {
        const tokens = await getUserTokens(userId);
        if (tokens.length > 0) {
          await sendNotification(
            tokens,
            {
              title: "תזכורת משמרת ⏰",
              body: `המשמרת שלך ב${department} מתחילה בעוד שעה (${startTime})`,
            },
            {
              type: "shift_reminder",
              shiftId: shiftId,
            }
          );
        }
      }

      // Mark reminder as sent to avoid duplicate notifications
      await db.collection("shifts").doc(shiftId).update({
        reminderSent: true,
      });

      console.log(`Sent shift reminder for shift ${shiftId}`);
    }
  }
});

/**
 * Callable: Delete a post by ID.
 * Managers and owners can delete any post; authors can delete their own.
 * Uses Admin SDK to bypass Firestore security rules.
 */
exports.deletePost = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

  const { postId } = request.data;
  if (!postId) throw new HttpsError("invalid-argument", "postId is required");

  const postDoc = await db.collection("posts").doc(postId).get();
  if (!postDoc.exists) throw new HttpsError("not-found", "Post not found");

  const authorId = postDoc.data().authorId;

  // Check role – managers and owners can delete any post
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
