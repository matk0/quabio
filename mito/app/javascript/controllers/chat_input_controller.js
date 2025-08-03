import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "form"]

  connect() {
    // Ensure the textarea has proper initial setup
    this.textareaTarget.style.resize = "none"
  }

  keydown(event) {
    // Handle Enter key
    if (event.key === "Enter") {
      if (event.shiftKey) {
        // Shift+Enter: Allow default behavior (new line)
        return
      } else {
        // Enter without shift: Submit form
        event.preventDefault()
        this.submitForm()
      }
    }
  }

  submitForm() {
    // Only submit if there's content (excluding whitespace)
    const content = this.textareaTarget.value.trim()
    if (content.length > 0) {
      this.formTarget.requestSubmit()
    }
  }

  // Optional: Auto-resize textarea as content grows
  input() {
    this.autoResize()
  }

  autoResize() {
    const textarea = this.textareaTarget
    
    // Reset height to auto to get the correct scrollHeight
    textarea.style.height = "auto"
    
    // Set height based on content, with min and max limits
    const minHeight = 44 // Minimum height in pixels
    const maxHeight = 120 // Maximum height in pixels
    
    let newHeight = Math.max(minHeight, textarea.scrollHeight)
    newHeight = Math.min(maxHeight, newHeight)
    
    textarea.style.height = newHeight + "px"
    
    // Show scrollbar if content exceeds max height
    if (textarea.scrollHeight > maxHeight) {
      textarea.style.overflowY = "auto"
    } else {
      textarea.style.overflowY = "hidden"
    }
  }
}