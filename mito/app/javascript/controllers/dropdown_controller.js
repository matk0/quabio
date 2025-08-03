import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open", "closed"]

  connect() {
    this.close()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.menuTarget.classList.add("block")
    this.isOpen = true
    
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeOnOutsideClick.bind(this))
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.menuTarget.classList.remove("block")
    this.isOpen = false
    
    // Remove outside click listener
    document.removeEventListener("click", this.closeOnOutsideClick.bind(this))
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick.bind(this))
  }
}