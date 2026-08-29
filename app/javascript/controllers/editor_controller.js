import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "fingerprint", "body", "h2Warning"]
  static values = {
    url: String,
    interval: { type: Number, default: 60000 }
  }

  connect() {
    this.dirty = false
    this.saving = false
    this.debounce = null
    this.timer = setInterval(() => this.saveIfDirty(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
    clearTimeout(this.debounce)
  }

  markDirty() {
    this.dirty = true
    clearTimeout(this.debounce)
    this.debounce = setTimeout(() => this.saveIfDirty(), 2000)
  }

  checkHeading() {
    if (!this.hasH2WarningTarget || !this.hasBodyTarget) return

    const hasH2 = this.bodyTarget.value.split(/\r?\n/).some((line) => /^(##)(?!#)(?: |$)/.test(line))
    this.h2WarningTarget.classList.toggle("is-visible", hasH2)
  }

  async saveIfDirty() {
    if (!this.dirty || this.saving || !this.hasFormTarget) return

    this.saving = true
    if (this.hasStatusTarget) this.statusTarget.textContent = "Saving…"

    const data = new FormData(this.formTarget)
    data.set("intent", "save")

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: data
      })
      const payload = await response.json()

      if (response.status === 409) {
        this.dirty = false
        if (this.hasStatusTarget) this.statusTarget.textContent = payload.message
        return
      }

      if (!response.ok) {
        if (this.hasStatusTarget) this.statusTarget.textContent = payload.message || "Could not save Memory."
        return
      }

      this.dirty = false
      if (this.hasFingerprintTarget && payload.fingerprint) {
        this.fingerprintTarget.value = payload.fingerprint
      }
      if (this.hasStatusTarget) this.statusTarget.textContent = payload.saved_label || "Saved"
    } catch (_error) {
      if (this.hasStatusTarget) this.statusTarget.textContent = "Could not save Memory."
    } finally {
      this.saving = false
    }
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
