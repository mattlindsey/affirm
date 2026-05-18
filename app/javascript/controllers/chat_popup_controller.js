import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["openBtn", "backdrop", "closeBtn", "sendBtn", "input", "body"]

  connect() {
    if (!this.hasOpenBtnTarget || !this.hasBackdropTarget) {
      console.error("Chat popup elements not found")
      return
    }
  }

  open() {
    this.backdropTarget.classList.add("active")
    this.openBtnTarget.setAttribute("aria-hidden", "true")
    this.openBtnTarget.style.display = "none"
    setTimeout(() => this.inputTarget.focus(), 50)
  }

  close() {
    this.backdropTarget.classList.remove("active")
    this.openBtnTarget.removeAttribute("aria-hidden")
    this.openBtnTarget.style.display = ""
    this.openBtnTarget.focus()
  }

  closeOnBackdropClick(e) {
    if (e.target === this.backdropTarget) {
      this.close()
    }
  }

  handleKeyDown(e) {
    if (e.key === "Escape" && this.backdropTarget.classList.contains("active")) {
      this.close()
    }
  }

  send() {
    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage(message, "user")
    this.inputTarget.value = ""
    setTimeout(() => this.appendMessage("Thanks — this is a mock reply.\nYou can replace this with API logic later.", "bot"), 600)
  }

  handleEnter(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.send()
    }
  }

  appendMessage(text, who) {
    const wrapper = document.createElement("div")
    wrapper.className = `chat-msg ${who === "user" ? "user" : "bot"}`
    const p = document.createElement("p")
    p.textContent = text
    wrapper.appendChild(p)
    this.bodyTarget.appendChild(wrapper)
    this.bodyTarget.scrollTop = this.bodyTarget.scrollHeight
  }
}
