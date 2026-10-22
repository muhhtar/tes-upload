import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

const STYLE_TEMPLATES: Record<string, string> = {
  watercolor:
    "soft watercolor illustration, warm sepia tones, gentle light, nostalgic mood, no text, no logos",
  pencil:
    "delicate pencil sketch on cream paper, soft shading, nostalgic, no text",
  vintage:
    "vintage faded photograph look, warm film grain, 1990s feel, no text",
  storybook:
    "children's storybook illustration, cozy colors, whimsical, no text",
};

export const generateIllustration = functions.https.onCall(
  async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Silakan masuk ke akunmu terlebih dahulu."
      );
    }

    const uid = context.auth.uid;
    const memoryId = data.memoryId as string;
    const style = (data.style as string) || "watercolor";

    if (!memoryId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "memoryId wajib diisi."
      );
    }

    if (!STYLE_TEMPLATES[style]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Gaya ilustrasi tidak valid."
      );
    }

    // 2. Verify Memory Ownership
    const memoryRef = db.collection("memories").doc(memoryId);
    const memorySnap = await memoryRef.get();

    if (!memorySnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Kenangan tidak ditemukan."
      );
    }

    const memoryData = memorySnap.data()!;
    if (memoryData.user_id !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Kamu tidak memiliki akses ke kenangan ini."
      );
    }

    // 3. Quota check (max 5/day) via Firestore Transaction
    const userRef = db.collection("users").doc(uid);
    const now = new Date();

    await db.runTransaction(async (transaction) => {
      const userSnap = await transaction.get(userRef);
      let usedToday = 0;
      let resetAt: Date | null = null;

      if (userSnap.exists && userSnap.data()?.ai_quota) {
        const quota = userSnap.data()?.ai_quota;
        usedToday = quota.used_today || 0;
        resetAt = quota.reset_at ? quota.reset_at.toDate() : null;
      }

      // Reset quota if 24 hours passed
      if (!resetAt || now.getTime() - resetAt.getTime() > 24 * 60 * 60 * 1000) {
        usedToday = 0;
        resetAt = now;
      }

      if (usedToday >= 5) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "Kuota harianmu sudah habis (maksimal 5 kali sehari). Coba lagi besok ya."
        );
      }

      transaction.set(
        userRef,
        {
          ai_quota: {
            used_today: usedToday + 1,
            reset_at: resetAt,
          },
        },
        { merge: true }
      );
    });

    // 4. Moderate story content
    const title = memoryData.title || "";
    const story = memoryData.story || "";
    const fullText = `${title}. ${story}`.trim();

    if (fullText.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cerita kenangan tidak boleh kosong untuk membuat ilustrasi."
      );
    }

    // 5. Construct AI Prompt
    const stylePrompt = STYLE_TEMPLATES[style];
    const prompt = `A nostalgic illustration inspired by: "${title}". ${stylePrompt}`;

    // 6. Generate Image Placeholder / AI Provider Call
    // Note: IMAGE_API_KEY from secret manager can be read here: process.env.IMAGE_API_KEY
    const storagePath = `users/${uid}/memories/${memoryId}/ai_illustration.png`;

    // For demonstration / placeholder generation in emulator / cloud:
    // Generate a stylized image placeholder URL or call image API provider
    const sampleImageUrl = `https://picsum.photos/seed/${memoryId}_${style}/600/600`;

    // 7. Update Firestore Memory Document
    const illustrationData = {
      url: sampleImageUrl,
      path: storagePath,
      style: style,
      status: "done",
      generated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await memoryRef.update({
      ai_illustration: illustrationData,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      url: sampleImageUrl,
      path: storagePath,
      style: style,
      status: "done",
    };
  }
);
