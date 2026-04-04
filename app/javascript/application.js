// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Configure Turbo progress bar
import * as Turbo from "@hotwired/turbo"
Turbo.setProgressBarDelay(100) // Show after 100ms delay

// Global loading overlay for form submissions
document.addEventListener("turbo:submit-start", (event) => {
  const overlay = document.getElementById("loading-overlay")
  if (overlay) overlay.classList.add("active")

  // Disable submit button
  const submitBtn = event.target.querySelector('button[type="submit"], input[type="submit"]')
  if (submitBtn) {
    submitBtn.disabled = true
  }
})

document.addEventListener("turbo:submit-end", () => {
  const overlay = document.getElementById("loading-overlay")
  if (overlay) overlay.classList.remove("active")
})

// Hide overlay on any Turbo render
document.addEventListener("turbo:render", () => {
  const overlay = document.getElementById("loading-overlay")
  if (overlay) overlay.classList.remove("active")
})

// Hide overlay on frame load
document.addEventListener("turbo:frame-load", () => {
  const overlay = document.getElementById("loading-overlay")
  if (overlay) overlay.classList.remove("active")
})
