import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["openBtn", "backdrop", "closeBtn", "sendBtn", "input", "body"]

  connect() {
    this.history = []
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

  async send() {
    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage(message, "user")
    this.inputTarget.value = ""
    this.setLoading(true)

    const typingEl = this.appendTyping()

    try {
      const response = await fetch("/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ message, history: this.history })
      })

      const data = await response.json()
      typingEl.remove()

      if (response.ok) {
        this.appendMessage(data.reply, "bot")
        this.history.push({ role: "user", content: message })
        this.history.push({ role: "assistant", content: data.reply })
      } else {
        this.appendMessage("Sorry, I couldn't respond right now.", "bot")
      }
    } catch {
      typingEl.remove()
      this.appendMessage("Unable to connect. Check API key and please try again.", "bot")
    } finally {
      this.setLoading(false)
    }
  }

  handleEnter(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.send()
    }
  }

  setLoading(loading) {
    this.inputTarget.disabled = loading
    this.sendBtnTarget.disabled = loading
  }

  appendTyping() {
    const wrapper = document.createElement("div")
    wrapper.className = "chat-msg bot"
    wrapper.innerHTML = "<p>…</p>"
    this.bodyTarget.appendChild(wrapper)
    this.bodyTarget.scrollTop = this.bodyTarget.scrollHeight
    return wrapper
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
