import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status", "fingerprint", "body", "h2Warning", "upload", "uploadStatus", "keyPhoto", "keyPhotoPlaceholder"]
  static values = {
    url: String,
    uploadUrl: String,
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

  async upload(event) {
    const input = event.target
    const file = input.files && input.files[0]
    if (!file || !this.hasBodyTarget || !this.hasUploadUrlValue) return

    input.disabled = true
    if (this.hasUploadStatusTarget) this.uploadStatusTarget.textContent = "Processing…"

    const data = new FormData()
    data.set("image", file)
    if (this.hasFingerprintTarget) data.set("source_fingerprint", this.fingerprintTarget.value)

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: data
      })
      const payload = await response.json()

      if (response.status === 409) {
        if (this.hasUploadStatusTarget) this.uploadStatusTarget.textContent = payload.message
        if (this.hasStatusTarget) this.statusTarget.textContent = payload.message
        return
      }

      if (!response.ok) {
        if (this.hasUploadStatusTarget) {
          this.uploadStatusTarget.textContent = payload.message || "Image processing failed."
        }
        return
      }

      this.appendToMarkdown(payload.markdown)
      if (this.hasFingerprintTarget && payload.fingerprint) {
        this.fingerprintTarget.value = payload.fingerprint
      }
      this.ensureKeyPhotoOption(payload.key_photo)
      this.ensureKeyPhotoOption((payload.markdown || "").match(/\(([^)]+)\)/)?.[1])
      if (this.hasUploadStatusTarget) this.uploadStatusTarget.textContent = ""
      this.dirty = true
      await this.saveIfDirty()
    } catch (_error) {
      if (this.hasUploadStatusTarget) this.uploadStatusTarget.textContent = "Image processing failed."
    } finally {
      input.value = ""
      input.disabled = false
    }
  }

  appendToMarkdown(markdown) {
    if (!markdown || !this.hasBodyTarget) return

    const textarea = this.bodyTarget
    const value = textarea.value
    const separator = value.length === 0 ? "" : (value.endsWith("\n") ? "\n" : "\n\n")
    textarea.value = value + separator + markdown
    const pos = textarea.value.length
    textarea.focus()
    textarea.setSelectionRange(pos, pos)
    this.checkHeading()
  }

  ensureKeyPhotoOption(name) {
    if (!this.hasKeyPhotoTarget || !name) return

    const select = this.keyPhotoTarget
    ;[...select.options].filter((option) => option.value === "").forEach((option) => option.remove())
    if (![...select.options].some((option) => option.value === name)) {
      select.add(new Option(name, name))
    }
    if (this.hasKeyPhotoPlaceholderTarget) this.keyPhotoPlaceholderTarget.hidden = true
    select.hidden = false
    if (!select.value) select.value = name
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
