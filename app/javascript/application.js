// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// #region agent log
function agentDebugLog(location, message, data, hypothesisId) {
  const payload = JSON.stringify({
    sessionId: "396a12",
    runId: "pre-fix",
    hypothesisId,
    location,
    message,
    data,
    timestamp: Date.now()
  })
  fetch("http://127.0.0.1:7915/ingest/ba236890-3b17-4036-884e-eaa367116031", { method: "POST", headers: { "Content-Type": "application/json", "X-Debug-Session-Id": "396a12" }, body: payload }).catch(() => {})
  fetch("/__debug_log", { method: "POST", headers: { "Content-Type": "application/json" }, body: payload, keepalive: true }).catch(() => {})
}

function agentViewportSnapshot(reason) {
  const stage = document.querySelector(".present-stage")
  const photo = document.querySelector(".present-photo")
  const present = document.querySelector(".present")
  const timeline = document.querySelector(".timeline")
  const vv = window.visualViewport
  const htmlCs = getComputedStyle(document.documentElement)
  const bodyCs = getComputedStyle(document.body)
  const stageCs = stage ? getComputedStyle(stage) : null
  const photoRect = photo ? photo.getBoundingClientRect() : null
  const longEdge = Math.max(screen.width, screen.height)
  const shortEdge = Math.min(screen.width, screen.height)
  const ref19p5Height = longEdge * 9 / 19.5
  agentDebugLog("application.js:agentViewportSnapshot", reason, {
    reason,
    path: location.pathname + location.search,
    mode: present ? "PRESENT" : (timeline ? "TIMELINE" : "OTHER"),
    orientation: (screen.orientation && screen.orientation.type) || (innerWidth > innerHeight ? "landscape" : "portrait"),
    innerWidth,
    innerHeight,
    clientHeight: document.documentElement.clientHeight,
    screenW: screen.width,
    screenH: screen.height,
    shortEdge,
    longEdge,
    dpr: devicePixelRatio,
    vvW: vv && vv.width,
    vvH: vv && vv.height,
    scrollY,
    scrollHeight: document.documentElement.scrollHeight,
    bodyScrollHeight: document.body.scrollHeight,
    htmlOverflow: htmlCs.overflow,
    bodyOverflow: bodyCs.overflow,
    htmlHeight: htmlCs.height,
    bodyHeight: bodyCs.height,
    canScroll: document.documentElement.scrollHeight > window.innerHeight + 1,
    stageW: stageCs && stageCs.width,
    stageH: stageCs && stageCs.height,
    photoW: photoRect && Math.round(photoRect.width),
    photoH: photoRect && Math.round(photoRect.height),
    photoMaxH: photo && getComputedStyle(photo).maxHeight,
    ref19p5Height: Math.round(ref19p5Height),
    targetImageMin900: Math.max(900, Math.round(ref19p5Height * 0.8)),
    targetImage80ofShort: Math.round(shortEdge * 0.8),
    targetImage80ofShortDevicePx: Math.round(shortEdge * devicePixelRatio * 0.8)
  }, present ? "B" : "E")
}

window.__agentViewportSnapshot = agentViewportSnapshot
document.addEventListener("turbo:load", () => agentViewportSnapshot("turbo:load"))
window.addEventListener("orientationchange", () => {
  window.setTimeout(() => agentViewportSnapshot("orientationchange"), 400)
})
// #endregion
