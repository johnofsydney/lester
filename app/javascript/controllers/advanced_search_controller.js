import { Controller } from "@hotwired/stimulus"

// Drives the repeatable filter-row builder on the advanced search form: adding/removing
// rows, swapping the Category <select> for a Group typeahead per row, and the typeahead
// itself (debounced fetch against AdvancedSearchController#group_autocomplete).
export default class extends Controller {
  static targets = ["rows", "template"]
  static values = { groupsUrl: String }

  connect() {
    this.nextIndex = this.rowsTarget.querySelectorAll('[data-advanced-search-target="row"]').length
    this.boundHideSuggestions = this.hideSuggestions.bind(this)
    document.addEventListener("click", this.boundHideSuggestions)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHideSuggestions)
    clearTimeout(this.debounceTimer)
  }

  addRow() {
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", this.nextIndex)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.nextIndex += 1
  }

  removeRow(event) {
    const rows = this.rowsTarget.querySelectorAll('[data-advanced-search-target="row"]')
    if (rows.length <= 1) return

    event.currentTarget.closest('[data-advanced-search-target="row"]').remove()
  }

  toggleFacetType(event) {
    const row = event.currentTarget.closest('[data-advanced-search-target="row"]')
    const isGroup = event.currentTarget.value === "Group"

    const categoryFacet = row.querySelector('[data-advanced-search-target="categoryFacet"]')
    const groupFacet = row.querySelector('[data-advanced-search-target="groupFacet"]')

    categoryFacet.classList.toggle("d-none", isGroup)
    categoryFacet.querySelector("select").disabled = isGroup

    groupFacet.classList.toggle("d-none", !isGroup)
    groupFacet.querySelector('[data-advanced-search-target="groupHidden"]').disabled = !isGroup
  }

  searchGroups(event) {
    const input = event.currentTarget
    const row = input.closest('[data-advanced-search-target="row"]')
    const suggestions = row.querySelector('[data-advanced-search-target="suggestions"]')
    const hidden = row.querySelector('[data-advanced-search-target="groupHidden"]')

    hidden.value = ""
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchGroups(input, suggestions, hidden), 250)
  }

  async fetchGroups(input, suggestions, hidden) {
    const term = input.value.trim()

    if (term.length < 2) {
      this.clearSuggestions(suggestions)
      return
    }

    const response = await fetch(`${this.groupsUrlValue}?term=${encodeURIComponent(term)}`, {
      headers: { Accept: "application/json" }
    })

    if (!response.ok) {
      this.clearSuggestions(suggestions)
      return
    }

    const groups = await response.json()
    suggestions.innerHTML = ""

    groups.forEach((group) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "list-group-item list-group-item-action"
      button.textContent = group.name
      button.addEventListener("click", () => {
        input.value = group.name
        hidden.value = group.id
        this.clearSuggestions(suggestions)
      })
      suggestions.appendChild(button)
    })

    suggestions.classList.toggle("d-none", groups.length === 0)
  }

  clearSuggestions(suggestions) {
    suggestions.innerHTML = ""
    suggestions.classList.add("d-none")
  }

  hideSuggestions(event) {
    this.element.querySelectorAll('[data-advanced-search-target="suggestions"]').forEach((suggestions) => {
      if (!suggestions.parentElement.contains(event.target)) this.clearSuggestions(suggestions)
    })
  }
}
