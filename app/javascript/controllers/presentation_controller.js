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
    if (window.Turbo) window.Turbo.visit(url)
    else window.location = url
  }
}
