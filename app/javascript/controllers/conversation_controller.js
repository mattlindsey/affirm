import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "sendBtn"]

  disableSend() {
    this.sendBtnTarget.disabled = true
    this.sendBtnTarget.textContent = "…"
  }

  enableSend() {
    this.sendBtnTarget.disabled = false
    this.sendBtnTarget.textContent = "Send"
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.#scrollToBottom()
  }

  #scrollToBottom() {
    const messages = document.getElementById("messages")
    if (messages) messages.scrollTop = messages.scrollHeight
  }
}
