const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

exports.sendNotificationOnClaim = onDocumentCreated("claimed_food/{claimId}", async (event) => {
  const data = event.data?.data();
  if (!data) {
    logger.warn("No data in event.");
    return;
  }

  const donorId = data.donorId;
  const donorDoc = await admin.firestore().collection("users").doc(donorId).get();

  if (!donorDoc.exists || !donorDoc.data().deviceToken) {
    logger.warn("Donor or FCM token not found");
    return;
  }

  const token = donorDoc.data().deviceToken;

  const message = {
    notification: {
      title: "🎉 Your food was claimed!",
      body: "A receiver has claimed your donation.",
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    logger.info("Notification sent:", response);
  } catch (error) {
    logger.error("Error sending notification:", error);
  }
});




exports.notifyReceiversOnFoodUpload = onDocumentCreated("surplus_food/{foodId}", async (event) => {
  const newFood = event.data?.data();
  if (!newFood) {
    logger.warn("No food data found");
    return;
  }

  const foodTitle = newFood.foodTitle || "New Food Item";

  const receiverSnapshot = await admin.firestore()
    .collection("users")
    .where("role", "==", "receiver")
    .get();

  const tokens = [];

  receiverSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.deviceToken) {
      tokens.push(data.deviceToken);
    }
  });

  if (tokens.length === 0) {
    logger.info("No receiver tokens found.");
    return;
  }

  const message = {
    notification: {
      title: "🍽️ New Food Available!",
      body: `${foodTitle} has just been added.`,
    },
    data: {
      surplusId: event.params.foodId,
      click_action: "FLUTTER_NOTIFICATION_CLICK" // for Android deep linking
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    logger.info(`Notifications sent: ${response.successCount}, failures: ${response.failureCount}`);
  } catch (error) {
    logger.error("Error sending multicast notification:", error);
  }
});











