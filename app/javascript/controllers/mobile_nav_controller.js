import { Controller } from "@hotwired/stimulus"

// Mobile dropdown for the primary nav links, which are hidden below `md`
// and shown inline at `md` and up. A hamburger button toggles the panel.
export default class extends Controller {
  static targets = ["button", "menu", "openIcon", "closeIcon"]

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.isOpen = true
    this.menuTarget.classList.remove("hidden")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.isOpen = false
    this.menuTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
