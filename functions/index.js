/**
 * Firebase Cloud Functions for Park Janana
 * Handles push notifications for:
 * - Shift assignments
 * - Task assignments
 * - New messages in shifts
 */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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
    (w) => w.odekId || w.odek_id
  );
  const afterRejected = (afterData.rejectedWorkerData || []).map(
    (w) => w.odekId || w.odek_id
  );

  const newlyRejected = afterRejected.filter(
    (uid) => uid && !beforeRejected.includes(uid)
  );

  // Send notification to rejected workers
  for (const odekId of newlyRejected) {
    // Find the actual user ID from the rejected data
    const rejectedWorker = afterData.rejectedWorkerData.find(
      (w) => (w.odekId || w.odek_id) === odekId
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

    const senderName = newMessage.senderName || "מנהל";
    const messageText = newMessage.text || "";
    const senderId = newMessage.senderId;

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

    const commenterName = newComment.userName || "משתמש";
    const commentText = newComment.text || "";
    const commenterId = newComment.userId;
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
