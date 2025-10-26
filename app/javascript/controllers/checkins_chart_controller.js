import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { labels: Array, values: Array }

  connect() {
    // Ensure canvas uses container width
    this.element.style.width = '100%'

    // Try to create chart (retry briefly if Chart.js not yet available)
    this._retryCount = 0
    this._maxRetries = 10
    const tryCreate = () => {
      if (window.Chart) return this.createChart()
      this._retryCount += 1
      if (this._retryCount <= this._maxRetries) setTimeout(tryCreate, 200)
      else {
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
      // destroy existing chart on this canvas (if any)
      if (typeof ChartCtor.getChart === 'function') {
        const existing = ChartCtor.getChart(this.element)
        if (existing) try { existing.destroy() } catch(_) {}
      }
  const rawValues = this.valuesValue.map(v => (v === null || v === undefined) ? null : Number(v))
  const nonNullValues = rawValues.filter(v => v !== null)
  const maxValue = nonNullValues.length ? Math.max(...nonNullValues) : 1
  const minValue = nonNullValues.length ? Math.min(...nonNullValues) : 0
  const goalValue = Number(this.element.dataset.checkinsChartGoalValue || 0)
  let suggestedMax = Math.ceil(maxValue + Math.max(0.5, Math.round(maxValue * 0.15)))
  // if this is a Mood chart, clamp to 10 and use step 1
  const yTitle = this.element.dataset.checkinsChartYTitle || this.element.dataset.checkinsChartXTitle || ''
  const isMood = String(yTitle).toLowerCase().includes('mood')
  if (isMood) {
    // force mood scale 1..10
    suggestedMax = 10
  }
  const integerSteps = true
  // plugin to draw values above bars (only non-null and non-zero values)
  const valueLabelsPlugin = {
    id: 'valueLabels',
    afterDatasetsDraw: (chart) => {
      const ctx = chart.ctx;
      chart.data.datasets.forEach((dataset, datasetIndex) => {
        const meta = chart.getDatasetMeta(datasetIndex);
        meta.data.forEach((bar, index) => {
          const value = dataset.data[index];
          if (value === null || value === undefined) return;
          // show 1 as valid value; only skip null/undefined
          if (Number(value) === 0) return; // still skip explicit zeros
          const x = bar.x;
          const y = bar.y - 6;
          ctx.save();
          ctx.fillStyle = '#111827';
          ctx.font = '600 11px system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'bottom';
          // format with 1 decimal if not integer
          const text = (Number(value) % 1 === 0) ? String(value) : String(Number(value).toFixed(1))
          ctx.fillText(text, x, y);
          ctx.restore();
        })
      })
    }
  }

  // plugin to draw a horizontal goal line if provided
    const goalLinePlugin = {
      id: 'goalLine',
      afterDraw: (chart) => {
        if (!goalValue || goalValue <= 0) return
        const yScale = chart.scales['y']
        const xScale = chart.scales['x']
        const ctx = chart.ctx
        const y = yScale.getPixelForValue(goalValue)
        ctx.save()
        ctx.beginPath()
        ctx.moveTo(xScale.left, y)
        ctx.lineTo(xScale.right, y)
        ctx.lineWidth = 2
        ctx.strokeStyle = '#ef7a1a'
        ctx.stroke()
        // draw label at right
        ctx.fillStyle = '#ef7a1a'
        ctx.font = '600 12px system-ui, -apple-system, "Segoe UI", Roboto'
        ctx.textAlign = 'right'
        ctx.fillText(String(goalValue), xScale.right - 6, y - 6)
        ctx.restore()
      }
    }

  // read optional x-axis title from data attribute
  const xTitle = this.element.dataset.checkinsChartXTitle || 'Month'
  const labelCount = this.labelsValue.length || 0
  const maxLabels = (xTitle === 'Month') ? 10 : 12
  const labelStep = Math.max(1, Math.ceil(labelCount / maxLabels))


  // Set canvas CSS height to the computed height but avoid changing internal pixel buffer
  try {
    const computed = getComputedStyle(this.element)
    const cssHeight = parseFloat(computed.height) || 300
    this.element.style.width = '100%'
    this.element.style.height = cssHeight + 'px'
  } catch(_) {}

  this.chart = new ChartCtor(this.element, {
        type: "bar",
        data: {
          labels: this.labelsValue,
          datasets: [{
            label: isMood ? "Mood" : "Check-ins",
            data: rawValues,
  backgroundColor: isMood ? "rgba(99,102,241,0.9)" : "rgba(99,102,241,0.9)",
  borderRadius: 4,
  barPercentage: 0.65,
  categoryPercentage: 0.85
          }]
        },
        options: {
          layout: { padding: { top: 6, left: 12, right: 8, bottom: 6 } },
          responsive: false,
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
        autoSkip: true,
        autoSkipPadding: 6,
        maxTicksLimit: maxLabels,
        maxRotation: (xTitle === 'Last 30 days') ? 30 : 55,
        minRotation: (xTitle === 'Last 30 days') ? 0 : 20,
                padding: 4,
        font: { size: (labelCount > 20) ? 10 : (labelCount > 12 ? 11 : 12) },
                callback: function(value, index) {
                  try {
                    const labels = this.chart?.data?.labels || []
                    const raw = labels[index] ?? ''
                    // if using 'Month' labels (1..31), show only the number, but for the first label show month+day
                    const showMonthDay = (xTitle === 'Month') || (/^[0-9]{1,2}$/.test(String(raw)) )
                    if (this.autoSkip) {
                      if (!showMonthDay) return raw
                      // when autoSkip hides some labels, still show numeric day for cleared ones
                      return showMonthDay ? String(raw) : ''
                    }
                    if (!showMonthDay) return raw
                    if (index === 0) {
                      // prefix month on the first label
                      const month = (new Date()).toLocaleString('en', { month: 'short' })
                      return `${month} ${String(raw)}`
                    }
                    return String(raw)
                  } catch(e) { return '' }
                }
              },
              title: {
                display: true,
                text: xTitle,
                color: 'rgba(120,120,120,0.9)',
                font: { size: 12 }
              }
            },
            y: {
              beginAtZero: !isMood,
              suggestedMax: suggestedMax,
              min: isMood ? 1 : undefined,
              max: isMood ? 10 : undefined,
              ticks: {
                color: 'rgba(100,100,100,0.9)',
                stepSize: isMood ? 1 : (integerSteps ? 1 : undefined),
                callback: function(val) { return String(val) }
              },
              grid: {
                color: 'rgba(0,0,0,0.06)',
                borderColor: 'rgba(0,0,0,0.12)'
              },
              title: {
                display: true,
                text: isMood ? 'Mood' : 'Check-ins',
                color: 'rgba(120,120,120,0.9)',
                font: { size: 12 }
              }
            }
          }
        }
  ,
        plugins: [valueLabelsPlugin, goalLinePlugin]
  })
  // render legend (goal line) if legend container exists
  try {
    const legendContainer = this.element.parentElement?.querySelector('[data-checkins-chart-legend]')
    if (legendContainer) {
      if (isMood) {
        legendContainer.innerHTML = `
          <div class="flex items-center gap-2 text-sm text-gray-700">
            <span style="width:18px;height:8px;background:#3f3cdd;border-radius:2px;display:inline-block;"></span>
            <span>Mood</span>
          </div>
        `
      } else if (goalValue > 0) {
        legendContainer.innerHTML = `
          <div class="flex items-center gap-2 text-sm text-gray-700">
            <span style="width:18px;height:8px;background:#3f3cdd;border-radius:2px;display:inline-block;"></span>
            <span>Check-ins</span>
          </div>
          <div class="flex items-center gap-2 text-sm text-gray-700">
            <span style="width:18px;height:2px;background:#ef7a1a;display:inline-block;margin-left:2px"></span>
            <span>Goal: ${goalValue}</span>
          </div>
        `
      } else {
        legendContainer.innerHTML = ''
      }
    }
  } catch(_) {}
        // mark canvas as rendered so fallback knows
        try { 
          this.element.dataset.chartRendered = 'true'
          // hide/update status element if present
          const status = this.element.parentElement?.querySelector('[data-checkins-chart-status]')
          if (status) status.style.display = 'none'
        } catch(_) {}
  // chart created successfully
  // Do a few delayed checks (100ms, 400ms, 1000ms) and call resize() once if the container size changed.
  try {
    const container = this.element.parentElement || this.element
    const initialRect = container.getBoundingClientRect()
    const checks = [100, 400, 1000]
    let resized = false
    checks.forEach((delay) => {
      setTimeout(() => {
        try {
          if (resized) return
          const rect = container.getBoundingClientRect()
          if (Math.abs(rect.width - initialRect.width) > 6 || Math.abs(rect.height - initialRect.height) > 6) {
            try { this.chart.resize() } catch(_) {}
            resized = true
          }
        } catch(_) {}
      }, delay)
    })
  } catch(_) {}

  // attach a debounced window resize handler so Chart updates on viewport changes
  try {
    this._resizeHandler = () => {
      if (this._resizeTimer) clearTimeout(this._resizeTimer)
      this._resizeTimer = setTimeout(() => { try { this.chart.resize() } catch(_) {} }, 150)
    }
    window.addEventListener('resize', this._resizeHandler)
  } catch(_) {}
      } catch(e) {
        // fail silently; chart will not render
      return
    }
  }

  // (window resize handler is attached inside createChart)

  disconnect() {
  this.chart?.destroy()
  if (this._turboListener) document.removeEventListener('turbo:load', this._turboListener)
  if (this._resizeHandler) window.removeEventListener('resize', this._resizeHandler)
  if (this._resizeTimer) clearTimeout(this._resizeTimer)
  }
}
