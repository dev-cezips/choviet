import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["postType", "marketplaceFields", "priceInput"]

  connect() {
    this.toggleMarketplaceFields()
    // If editing a marketplace post, ensure styles are correct
    const selectedType = this.postTypeTargets.find(input => input.checked)
    if (selectedType) {
      this.updatePostTypeStyles(selectedType)
    }
  }

  postTypeChanged(event) {
    this.toggleMarketplaceFields()
    this.updatePostTypeStyles(event.target)
  }

  updatePostTypeStyles(selectedRadio) {
    // Remove active styles from all labels
    this.postTypeTargets.forEach(radio => {
      const label = radio.closest('label')
      if (label) {
        label.classList.remove('border-blue-500', 'bg-blue-50')
      }
    })

    // Add active styles to selected label
    const selectedLabel = selectedRadio.closest('label')
    if (selectedLabel) {
      selectedLabel.classList.add('border-blue-500', 'bg-blue-50')
    }
  }

  toggleMarketplaceFields() {
    // More reliable way to get checked value
    const checked = this.element.querySelector("input[name='post[post_type]']:checked")
    const isMarketplace = checked && checked.value === "marketplace"
    
    // Use toggle for cleaner code
    this.marketplaceFieldsTarget.classList.toggle("hidden", !isMarketplace)
    
    // Set required attribute on price field
    if (this.hasPriceInputTarget) {
      this.priceInputTarget.required = isMarketplace
    }
  }

  formatPrice(event) {
    const input = event.target
    let value = input.value.replace(/[^\d]/g, '') // Remove non-digits
    
    if (value) {
      // Format with thousands separator
      value = parseInt(value).toLocaleString('ko-KR')
    }
    
    input.value = value
  }

  // Remove formatting before form submission
  prepareForSubmit(event) {
    if (this.hasPriceInputTarget) {
      const rawValue = this.priceInputTarget.value.replace(/[^\d]/g, '')
      this.priceInputTarget.value = rawValue
    }
  }
}