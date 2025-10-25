import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { labels: Array, values: Array }
  connect() {
  // controller initialized

  // responsive: let Chart.js handle sizing; keep CSS canvas sizing but do not force pixel width here
  this.element.style.width = "100%"
  this.element.style.height = "100%"

    // Try to create immediately; if Chart.js isn't available yet, retry for a short period
    this._retryCount = 0
    this._maxRetries = 10
    const tryCreate = () => {
      if (window.Chart) return this.createChart()
      this._retryCount += 1
      if (this._retryCount <= this._maxRetries) {
        setTimeout(tryCreate, 200)
      } else {
        // fallback: also listen for turbo:load once
        this._turboListener = () => { this.createChart() }
        document.addEventListener('turbo:load', this._turboListener)
      }
    }

    tryCreate()
  }

  createChart() {
    // avoid creating twice
    if (this.chart) return
    const ctx = this.element.getContext("2d")
    const ChartCtor = window.Chart
    if (!ChartCtor || typeof ChartCtor !== 'function') {
      return
    }
  // using window.Chart constructor
    try {
      // If Chart.js already created a chart on this canvas, destroy it so new options take effect
      if (typeof ChartCtor.getChart === 'function') {
        const existing = ChartCtor.getChart(this.element)
        if (existing) {
          try { existing.destroy() } catch(e) { /* ignore destroy errors */ }
        }
      }
      // Use canvas element directly — Chart.js accepts the element or 2d context.
  // compute sensible Y max and step
  const maxValue = Math.max(...this.valuesValue, 1)
  const suggestedMax = Math.ceil(maxValue + Math.max(1, Math.round(maxValue * 0.2)))
  const integerSteps = this.valuesValue.every(v => Number.isInteger(v))

  this.chart = new ChartCtor(this.element, {
        type: "bar",
        data: {
          labels: this.labelsValue,
          datasets: [{
            label: "Check-ins",
            data: this.valuesValue,
  backgroundColor: "rgba(99,102,241,0.9)",
  borderRadius: 4,
  barPercentage: 0.4,
  categoryPercentage: 0.5
          }]
        },
        options: {
          responsive: true,
          animation: { duration: 0 },
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            x: {
              type: 'category', // treat labels as categories (days) rather than numeric/time values
              grid: {
                color: 'rgba(0,0,0,0.06)',
                borderColor: 'rgba(0,0,0,0.12)'
              },
              ticks: {
                color: 'rgba(100,100,100,0.9)',
                autoSkip: false,
                maxTicksLimit: 12,
                maxRotation: 55,
                minRotation: 30,
                padding: 6,
                font: { size: 11 },
                callback: function(value, index) {
                  // show every label (months) but keep them short
                  try {
                    const labels = this.chart?.data?.labels || []
                    return labels[index] ?? ''
                  } catch(e) { return '' }
                }
              },
              title: {
                display: true,
                text: 'Month',
                color: 'rgba(120,120,120,0.9)',
                font: { size: 12 }
              }
            },
            y: {
              beginAtZero: true,
              suggestedMax: suggestedMax,
              ticks: {
                color: 'rgba(100,100,100,0.9)',
                stepSize: integerSteps ? 1 : undefined
              },
              grid: {
                color: 'rgba(0,0,0,0.06)',
                borderColor: 'rgba(0,0,0,0.12)'
              },
              title: {
                display: true,
                text: 'Check-ins',
                color: 'rgba(120,120,120,0.9)',
                font: { size: 12 }
              }
            }
          }
        }
  })
        // mark canvas as rendered so fallback knows
        try { 
          this.element.dataset.chartRendered = 'true'
          // hide/update status element if present
          const status = this.element.parentElement?.querySelector('[data-checkins-chart-status]')
          if (status) status.style.display = 'none'
        } catch(_) {}
  // chart created successfully
        // ensure layout size taken into account
        try { this.chart.resize() } catch(_) {}
      } catch(e) {
        // fail silently; chart will not render
      return
    }
  }

  disconnect() {
    this.chart?.destroy()
    if (this._turboListener) document.removeEventListener('turbo:load', this._turboListener)
  }
}
