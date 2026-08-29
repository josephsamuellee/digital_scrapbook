import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    prevUrl: String,
    nextUrl: String
  }

  connect() {
    this.onKey = this.onKey.bind(this)
    this.onTouchStart = this.onTouchStart.bind(this)
    this.onTouchEnd = this.onTouchEnd.bind(this)
    window.addEventListener("keydown", this.onKey)
    this.element.addEventListener("touchstart", this.onTouchStart, { passive: true })
    this.element.addEventListener("touchend", this.onTouchEnd)
    // #region agent log
    this.logPresentLayout("present-connect")
    this.element.querySelectorAll("img.present-photo").forEach((img) => {
      if (img.complete) this.logPresentLayout("present-photo-cached")
      else img.addEventListener("load", () => this.logPresentLayout("present-photo-load"), { once: true })
    })
    // #endregion
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
    this.element.removeEventListener("touchstart", this.onTouchStart)
    this.element.removeEventListener("touchend", this.onTouchEnd)
  }

  onKey(event) {
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey) return
    const tag = event.target && event.target.tagName
    if (tag === "INPUT" || tag === "TEXTAREA" || event.target.isContentEditable) return

    if (event.key === "ArrowRight" || event.key === "l") {
      event.preventDefault()
      this.visit(this.nextUrlValue)
    } else if (event.key === "ArrowLeft" || event.key === "h") {
      event.preventDefault()
      this.visit(this.prevUrlValue)
    }
  }

  onTouchStart(event) {
    const touch = event.changedTouches[0]
    this.touchStartX = touch.clientX
    this.touchStartY = touch.clientY
  }

  onTouchEnd(event) {
    if (this.touchStartX == null) return

    const touch = event.changedTouches[0]
    const dx = touch.clientX - this.touchStartX
    const dy = touch.clientY - this.touchStartY
    this.touchStartX = null
    this.touchStartY = null

    if (Math.abs(dx) < 50 || Math.abs(dx) < Math.abs(dy)) return

    if (dx < 0) this.visit(this.nextUrlValue)
    else this.visit(this.prevUrlValue)
  }

  visit(url) {
    if (!url) return
    // #region agent log
    this.logPresentLayout("present-visit", { nextUrl: url, scrollYBefore: window.scrollY })
    // #endregion
    if (window.Turbo) window.Turbo.visit(url)
    else window.location = url
  }

  // #region agent log
  logPresentLayout(reason, extra = {}) {
    const stage = this.element.querySelector(".present-stage")
    const photo = this.element.querySelector(".present-photo")
    const stageRect = stage && stage.getBoundingClientRect()
    const photoRect = photo && photo.getBoundingClientRect()
    const payload = JSON.stringify({
      sessionId: "396a12",
      runId: "pre-fix",
      hypothesisId: reason === "present-visit" ? "D" : "C",
      location: "presentation_controller.js:logPresentLayout",
      message: reason,
      data: {
        reason,
        overflowHidden: getComputedStyle(document.body).overflow.includes("hidden"),
        stageW: stageRect && Math.round(stageRect.width),
        stageH: stageRect && Math.round(stageRect.height),
        photoW: photoRect && Math.round(photoRect.width),
        photoH: photoRect && Math.round(photoRect.height),
        innerHeight: window.innerHeight,
        vvH: window.visualViewport && window.visualViewport.height,
        scrollY: window.scrollY,
        scrollHeight: document.documentElement.scrollHeight,
        ...extra
      },
      timestamp: Date.now()
    })
    fetch("http://127.0.0.1:7915/ingest/ba236890-3b17-4036-884e-eaa367116031", { method: "POST", headers: { "Content-Type": "application/json", "X-Debug-Session-Id": "396a12" }, body: payload }).catch(() => {})
    fetch("/__debug_log", { method: "POST", headers: { "Content-Type": "application/json" }, body: payload, keepalive: true }).catch(() => {})
  }
  // #endregion
}
