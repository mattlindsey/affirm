import { Controller } from "@hotwired/stimulus"

// Off-canvas conversation sidebar.
//
// Below the `md` breakpoint the sidebar is hidden off-screen so the chat gets
// the full viewport width (see issue #136). A hamburger button slides it in
// over a dimmed backdrop. At `md` and up the sidebar is always visible and this
// controller stays out of the way.
export default class extends Controller {
  static targets = ["panel", "backdrop", "toggle"]

  connect() {
    // The sidebar is omitted entirely when there are no conversations yet.
    if (!this.hasPanelTarget) return

    this.closeOnDesktop = this.closeOnDesktop.bind(this)
    this.desktopQuery = window.matchMedia("(min-width: 768px)")
    this.desktopQuery.addEventListener("change", this.closeOnDesktop)
    this.close()
  }

  disconnect() {
    this.desktopQuery?.removeEventListener("change", this.closeOnDesktop)
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasPanelTarget) return

    this.isOpen = true
    this.panelTarget.classList.remove("-translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    if (!this.hasPanelTarget) return

    this.isOpen = false
    this.panelTarget.classList.add("-translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")
    this.backdropTarget.classList.add("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("overflow-hidden")
  }

  // Close when Escape is pressed.
  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  // Reset state when the viewport grows past the breakpoint, so the sidebar
  // isn't left in an "open" state with the body scroll locked.
  closeOnDesktop(event) {
    if (event.matches) this.close()
  }
}
