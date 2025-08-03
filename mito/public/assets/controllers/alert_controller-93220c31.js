import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["alert"]
  static values = { 
    timeout: { type: Number, default: 4000 },
    slideInDuration: { type: Number, default: 300 },
    slideOutDuration: { type: Number, default: 200 }
  }

  connect() {
    this.slideIn()
    this.scheduleAutoHide()
  }

  slideIn() {
    // Start from off-screen right
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    
    // Force a reflow to ensure initial state is applied
    this.element.offsetHeight
    
    // Animate to visible position
    this.element.style.transition = `transform ${this.slideInDurationValue}ms cubic-bezier(0.25, 0.46, 0.45, 0.94), opacity ${this.slideInDurationValue}ms ease`
    this.element.style.transform = "translateX(0)"
    this.element.style.opacity = "1"
  }

  slideOut() {
    this.element.style.transition = `transform ${this.slideOutDurationValue}ms cubic-bezier(0.55, 0.06, 0.68, 0.19), opacity ${this.slideOutDurationValue}ms ease`
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    
    // Remove element after animation
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, this.slideOutDurationValue)
  }

  scheduleAutoHide() {
    this.hideTimeout = setTimeout(() => {
      this.slideOut()
    }, this.timeoutValue)
  }

  close() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
    }
    this.slideOut()
  }

  disconnect() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
    }
  }
}