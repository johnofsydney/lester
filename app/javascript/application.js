import "jquery"; // this import first
import 'bootstrap'

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "chartkick"
import "Chart.bundle"

function abbreviateAxisValue(value) {
  const abs = Math.abs(value)
  if (abs >= 1e9) return (value / 1e9).toFixed(1).replace(/\.0$/, '') + 'B'
  if (abs >= 1e6) return (value / 1e6).toFixed(1).replace(/\.0$/, '') + 'M'
  if (abs >= 1e3) return (value / 1e3).toFixed(1).replace(/\.0$/, '') + 'K'
  return value
}

function axisTickCallback(value) {
  if (this.type === 'category') return this.getLabelForValue(value)
  return `$${abbreviateAxisValue(value)}`
}

const axisTextColor = getComputedStyle(document.body).color

Chartkick.options = {
  library: {
    font: { family: getComputedStyle(document.body).fontFamily },
    scales: {
      y: { ticks: { color: axisTextColor, callback: axisTickCallback } },
      x: { ticks: { color: axisTextColor, callback: axisTickCallback } }
    }
  }
}