import { Controller } from "@hotwired/stimulus"

// Renders the typed message optimistically so it appears the instant Send is
// pressed instead of after the LLM answers (issue #166). The turbo_stream
// response removes the placeholder and appends the persisted messages, so the
// server stays the single source of truth for what the transcript contains.
export default class extends Controller {
  static targets = ["input", "sendBtn"]

  static PENDING_ID  = "pending_message"
  static THINKING_ID = "thinking"

  // Fired by Turbo once it has captured the form data, so clearing the input
  // here is safe.
  start() {
    const text = this.inputTarget.value.trim()
    if (text === "") return

    this.sendBtnTarget.disabled = true
    this.sendBtnTarget.textContent = "…"
    this.inputTarget.value = ""

    this.#append(this.#pendingBubble(text))
    this.#append(this.#thinkingBubble())
    this.#scrollToBottom()
  }

  finish() {
    this.sendBtnTarget.disabled = false
    this.sendBtnTarget.textContent = "Send"
    this.inputTarget.focus()
    document.getElementById(this.constructor.THINKING_ID)?.remove()
    this.#scrollToBottom()
  }

  #pendingBubble(text) {
    const bubble = document.createElement("div")
    bubble.id = this.constructor.PENDING_ID
    bubble.className = "chat-msg user"
    const paragraph = document.createElement("p")
    paragraph.textContent = text
    bubble.appendChild(paragraph)
    return bubble
  }

  #thinkingBubble() {
    const bubble = document.createElement("div")
    bubble.id = this.constructor.THINKING_ID
    bubble.className = "chat-msg assistant"
    bubble.setAttribute("role", "status")
    bubble.setAttribute("aria-label", "Coach is typing")
    bubble.innerHTML = '<p class="typing"><span></span><span></span><span></span></p>'
    return bubble
  }

  #append(bubble) {
    this.#messages()?.appendChild(bubble)
  }

  #messages() {
    return document.getElementById("messages")
  }

  #scrollToBottom() {
    const messages = this.#messages()
    if (messages) messages.scrollTop = messages.scrollHeight
  }
}
