// ============================================================
// Phase 2 placeholder.
// Right now this just shows a dash. In Phase 2 you'll replace
// API_URL with your real API Gateway endpoint, and this will
// fetch + increment the visitor count from Lambda -> DynamoDB.
// ============================================================

const API_URL = ""; // <-- paste your API Gateway invoke URL here in Phase 2

async function updateVisitorCount() {
  const el = document.getElementById("visitor-count");
  if (!API_URL) {
    el.textContent = "—"; // no API wired up yet
    return;
  }
  try {
    const res = await fetch(API_URL, { method: "POST" });
    const data = await res.json();
    el.textContent = data.count;
  } catch (err) {
    console.error("Visitor count failed:", err);
    el.textContent = "—";
  }
}

updateVisitorCount();
